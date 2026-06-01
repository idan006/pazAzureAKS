#!/usr/bin/env python3
"""Validate network exposure controls for the Azure Hub-Spoke AKS platform."""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
from dataclasses import dataclass, field
from typing import Any, Callable


class Color:
    RESET = "\033[0m"
    BOLD = "\033[1m"
    RED = "\033[31m"
    GREEN = "\033[32m"
    YELLOW = "\033[33m"
    BLUE = "\033[34m"
    CYAN = "\033[36m"


def supports_color() -> bool:
    return "NO_COLOR" not in os.environ and sys.stdout.isatty()


USE_COLOR = supports_color()


def paint(text: str, color: str) -> str:
    if not USE_COLOR:
        return text
    return f"{color}{text}{Color.RESET}"


def info(message: str) -> None:
    print(paint(f"[INFO] {message}", Color.CYAN))


def ok(message: str) -> None:
    print(paint(f"[PASS] {message}", Color.GREEN))


def warn(message: str) -> None:
    print(paint(f"[WARN] {message}", Color.YELLOW))


def fail(message: str) -> None:
    print(paint(f"[FAIL] {message}", Color.RED))


@dataclass
class Config:
    environment: str = "dev"
    project_name: str = "azure-hub-spoke-aks"
    subscription_id: str | None = None
    resource_group: str | None = None
    expected_appgw_public_ip: str | None = None
    expected_ingress_ip: str | None = None
    firewall_private_ip: str | None = None

    @property
    def prefix(self) -> str:
        return f"{self.project_name}-{self.environment}"

    @property
    def rg(self) -> str:
        return self.resource_group or f"{self.prefix}-rg"

    @property
    def aks_name(self) -> str:
        return f"{self.prefix}-aks"

    @property
    def appgw_name(self) -> str:
        return f"{self.prefix}-agw"

    @property
    def firewall_name(self) -> str:
        return f"{self.prefix}-afw"

    @property
    def firewall_policy_name(self) -> str:
        return f"{self.firewall_name}-policy"

    @property
    def firewall_rcg_name(self) -> str:
        return f"{self.firewall_name}-baseline-rcg"

    @property
    def route_table_name(self) -> str:
        return f"{self.prefix}-aks-udr"

    @property
    def hub_vnet_name(self) -> str:
        return f"{self.prefix}-hub-vnet"

    @property
    def spoke_vnet_name(self) -> str:
        return f"{self.prefix}-spoke-vnet"

    @property
    def ingress_ip(self) -> str:
        if self.expected_ingress_ip:
            return self.expected_ingress_ip
        return {
            "dev": "10.10.1.100",
            "qa": "10.20.1.100",
            "prod": "10.30.1.100",
        }.get(self.environment, "10.10.1.100")

    @property
    def firewall_ip(self) -> str:
        return self.firewall_private_ip or "10.0.0.4"


@dataclass
class CheckResult:
    name: str
    passed: bool
    details: list[str] = field(default_factory=list)
    errors: list[str] = field(default_factory=list)

    def add_pass(self, message: str) -> None:
        self.details.append(message)

    def add_error(self, message: str) -> None:
        self.passed = False
        self.errors.append(message)


class ValidationError(RuntimeError):
    pass


class Azure:
    def __init__(self, config: Config) -> None:
        self.config = config

    def json(self, args: list[str], allow_empty: bool = False) -> Any:
        cmd = ["az", *args, "-o", "json"]
        if self.config.subscription_id and "--subscription" not in args:
            cmd.extend(["--subscription", self.config.subscription_id])
        completed = subprocess.run(
            cmd,
            check=False,
            text=True,
            capture_output=True,
        )
        if completed.returncode != 0:
            message = completed.stderr.strip() or completed.stdout.strip()
            raise ValidationError(f"Command failed: {' '.join(cmd)}\n{message}")
        output = completed.stdout.strip()
        if not output and allow_empty:
            return None
        try:
            return json.loads(output)
        except json.JSONDecodeError as exc:
            raise ValidationError(f"Command did not return JSON: {' '.join(cmd)}") from exc


def result(name: str) -> CheckResult:
    return CheckResult(name=name, passed=True)


def has_public_ip_id(frontend: dict[str, Any]) -> bool:
    public_ip = frontend.get("publicIpId") or frontend.get("publicIPAddress")
    if isinstance(public_ip, dict):
        return bool(public_ip.get("id"))
    return bool(public_ip)


def check_no_internet_to_compute(az: Azure) -> CheckResult:
    cfg = az.config
    check = result("No direct internet connection to compute")

    aks = az.json([
        "aks",
        "show",
        "-g",
        cfg.rg,
        "-n",
        cfg.aks_name,
        "--query",
        "{privateCluster:apiServerAccessProfile.enablePrivateCluster,nodeResourceGroup:nodeResourceGroup,outboundType:networkProfile.outboundType}",
    ])
    if aks.get("privateCluster") is True:
        check.add_pass("AKS API is private.")
    else:
        check.add_error("AKS API is not private.")

    node_rg = aks.get("nodeResourceGroup")
    if not node_rg:
        check.add_error("AKS node resource group was not returned.")
        return check

    public_ips = az.json([
        "network",
        "public-ip",
        "list",
        "-g",
        node_rg,
        "--query",
        "[].{name:name,ip:ipAddress,attachedTo:ipConfiguration.id}",
    ])
    if public_ips:
        check.add_error(f"AKS node resource group has public IP resources: {public_ips}")
    else:
        check.add_pass("AKS node resource group has no public IP resources.")

    vmss_public_ip_configs = az.json([
        "vmss",
        "list",
        "-g",
        node_rg,
        "--query",
        "[].{name:name,publicIpConfig:virtualMachineProfile.networkProfile.networkInterfaceConfigurations[].ipConfigurations[].publicIPAddressConfiguration}",
    ])
    bad_vmss = [item for item in vmss_public_ip_configs if item.get("publicIpConfig")]
    if bad_vmss:
        check.add_error(f"AKS VMSS has public IP configuration: {bad_vmss}")
    else:
        check.add_pass("AKS VMSS network profile has no public IP configuration.")

    load_balancers = az.json([
        "network",
        "lb",
        "list",
        "-g",
        node_rg,
        "--query",
        "[].{name:name,frontendIps:frontendIPConfigurations[].{name:name,privateIp:privateIPAddress,publicIpId:publicIPAddress.id}}",
    ])
    public_lbs = []
    for lb in load_balancers:
        for frontend in lb.get("frontendIps") or []:
            if has_public_ip_id(frontend):
                public_lbs.append({"lb": lb.get("name"), "frontend": frontend})
    if public_lbs:
        check.add_error(f"AKS node resource group has public load balancer frontends: {public_lbs}")
    else:
        check.add_pass("AKS load balancer frontends are private-only.")

    nsgs = az.json([
        "network",
        "nsg",
        "list",
        "-g",
        cfg.rg,
        "--query",
        "[].{name:name,rules:securityRules[?direction==`Inbound`].{name:name,priority:priority,access:access,source:sourceAddressPrefix,sourcePrefixes:sourceAddressPrefixes,destination:destinationAddressPrefix,destPort:destinationPortRange,destPorts:destinationPortRanges}}",
    ])
    spoke_nsgs = [nsg for nsg in nsgs if f"{cfg.spoke_vnet_name}-" in nsg.get("name", "")]
    missing_deny = []
    internet_allows = []
    for nsg in spoke_nsgs:
        rules = nsg.get("rules") or []
        has_deny = any(
            rule.get("name") == "DenyInternetInbound"
            and rule.get("access") == "Deny"
            and rule.get("source") == "Internet"
            for rule in rules
        )
        if not has_deny:
            missing_deny.append(nsg.get("name"))
        for rule in rules:
            sources = [rule.get("source"), *(rule.get("sourcePrefixes") or [])]
            if rule.get("access") == "Allow" and any(src in ("Internet", "*") for src in sources):
                internet_allows.append({"nsg": nsg.get("name"), "rule": rule})
    if missing_deny:
        check.add_error(f"Spoke NSGs missing DenyInternetInbound: {missing_deny}")
    else:
        check.add_pass("Spoke NSGs include DenyInternetInbound.")
    if internet_allows:
        check.add_error(f"Spoke NSGs include inbound Internet allow rules: {internet_allows}")
    else:
        check.add_pass("No spoke NSG custom inbound allow from Internet was found.")

    return check


def check_app_gateway_only(az: Azure) -> CheckResult:
    cfg = az.config
    check = result("Only inbound application path is Application Gateway")

    public_ips = az.json([
        "network",
        "public-ip",
        "list",
        "-g",
        cfg.rg,
        "--query",
        "[].{name:name,ip:ipAddress,attachedTo:ipConfiguration.id}",
    ])
    public_ip_names = {item.get("name") for item in public_ips}
    if f"{cfg.appgw_name}-pip" in public_ip_names:
        check.add_pass("Application Gateway public IP exists.")
    else:
        check.add_error("Application Gateway public IP was not found.")

    appgw = az.json([
        "network",
        "application-gateway",
        "show",
        "-g",
        cfg.rg,
        "-n",
        cfg.appgw_name,
        "--query",
        "{state:provisioningState,operationalState:operationalState,frontendPublicIpIds:frontendIPConfigurations[].publicIPAddress.id,backendIps:backendAddressPools[].backendAddresses[].ipAddress,backendPorts:backendHttpSettingsCollection[].port}",
    ])
    if appgw.get("state") == "Succeeded" and appgw.get("operationalState") == "Running":
        check.add_pass("Application Gateway is provisioned and running.")
    else:
        check.add_error(f"Application Gateway is not healthy: {appgw}")

    backend_ips = appgw.get("backendIps") or []
    backend_ports = appgw.get("backendPorts") or []
    if backend_ips == [cfg.ingress_ip] and backend_ports == [80]:
        check.add_pass(f"Application Gateway backend is {cfg.ingress_ip}:80.")
    else:
        check.add_error(f"Unexpected Application Gateway backend: ips={backend_ips}, ports={backend_ports}")

    health = az.json([
        "network",
        "application-gateway",
        "show-backend-health",
        "-g",
        cfg.rg,
        "-n",
        cfg.appgw_name,
        "--query",
        "backendAddressPools[].backendHttpSettingsCollection[].servers[].{address:address,health:health,healthProbeLog:healthProbeLog}",
    ])
    unhealthy = [server for server in health if server.get("health") != "Healthy"]
    if unhealthy:
        check.add_error(f"Application Gateway has unhealthy backend servers: {unhealthy}")
    else:
        check.add_pass("Application Gateway backend health is Healthy.")

    firewall_rcg = az.json([
        "rest",
        "--method",
        "get",
        "--url",
        (
            "https://management.azure.com"
            f"/subscriptions/{cfg.subscription_id or az.json(['account', 'show', '--query', 'id'])}"
            f"/resourceGroups/{cfg.rg}"
            f"/providers/Microsoft.Network/firewallPolicies/{cfg.firewall_policy_name}"
            f"/ruleCollectionGroups/{cfg.firewall_rcg_name}"
            "?api-version=2024-05-01"
        ),
        "--query",
        "{ruleCollections:properties.ruleCollections[].{name:name,type:ruleCollectionType,rules:rules[].{name:name,ruleType:ruleType,translatedAddress:translatedAddress,translatedPort:translatedPort}}}",
    ])
    nat_rules = []
    for collection in firewall_rcg.get("ruleCollections") or []:
        if collection.get("type") == "FirewallPolicyNatRuleCollection":
            nat_rules.append(collection)
        for rule in collection.get("rules") or []:
            if rule.get("translatedAddress") or rule.get("translatedPort") or rule.get("ruleType") == "NatRule":
                nat_rules.append({"collection": collection.get("name"), "rule": rule})
    if nat_rules:
        check.add_error(f"Azure Firewall has DNAT/NAT rules that could create another inbound path: {nat_rules}")
    else:
        check.add_pass("Azure Firewall policy has no DNAT/NAT inbound rules.")

    return check


def check_vnet_peering_only(az: Azure) -> CheckResult:
    cfg = az.config
    check = result("Networking between hub and spoke is only VNet peering")

    hub_peerings = az.json([
        "network",
        "vnet",
        "peering",
        "list",
        "-g",
        cfg.rg,
        "--vnet-name",
        cfg.hub_vnet_name,
        "--query",
        "[].{name:name,state:peeringState,remote:remoteVirtualNetwork.id,allowVnetAccess:allowVirtualNetworkAccess,allowForwarded:allowForwardedTraffic}",
    ])
    spoke_peerings = az.json([
        "network",
        "vnet",
        "peering",
        "list",
        "-g",
        cfg.rg,
        "--vnet-name",
        cfg.spoke_vnet_name,
        "--query",
        "[].{name:name,state:peeringState,remote:remoteVirtualNetwork.id,allowVnetAccess:allowVirtualNetworkAccess,allowForwarded:allowForwardedTraffic}",
    ])
    if len(hub_peerings) == 1 and hub_peerings[0].get("state") == "Connected":
        check.add_pass("Hub-to-spoke peering is Connected.")
    else:
        check.add_error(f"Unexpected hub peering state: {hub_peerings}")
    if len(spoke_peerings) == 1 and spoke_peerings[0].get("state") == "Connected":
        check.add_pass("Spoke-to-hub peering is Connected.")
    else:
        check.add_error(f"Unexpected spoke peering state: {spoke_peerings}")

    gateways = az.json([
        "network",
        "vnet-gateway",
        "list",
        "-g",
        cfg.rg,
        "--query",
        "[].{name:name,type:gatewayType,provisioningState:provisioningState}",
    ])
    express_routes = az.json([
        "network",
        "express-route",
        "list",
        "-g",
        cfg.rg,
        "--query",
        "[].{name:name,provisioningState:provisioningState}",
    ])
    nat_gateways = az.json([
        "network",
        "nat",
        "gateway",
        "list",
        "-g",
        cfg.rg,
        "--query",
        "[].{name:name,provisioningState:provisioningState}",
    ])
    if gateways:
        check.add_error(f"VNet gateways found: {gateways}")
    else:
        check.add_pass("No VNet gateways found.")
    if express_routes:
        check.add_error(f"ExpressRoute circuits found: {express_routes}")
    else:
        check.add_pass("No ExpressRoute circuits found.")
    if nat_gateways:
        check.add_error(f"NAT gateways found: {nat_gateways}")
    else:
        check.add_pass("No NAT gateways found.")

    route_table = az.json([
        "network",
        "route-table",
        "show",
        "-g",
        cfg.rg,
        "-n",
        cfg.route_table_name,
        "--query",
        "{routes:routes[].{name:name,prefix:addressPrefix,nextHopType:nextHopType,nextHopIp:nextHopIpAddress},subnets:subnets[].id}",
    ])
    routes = route_table.get("routes") or []
    default_routes = [route for route in routes if route.get("prefix") == "0.0.0.0/0"]
    expected_default = any(
        route.get("nextHopType") == "VirtualAppliance" and route.get("nextHopIp") == cfg.firewall_ip
        for route in default_routes
    )
    if expected_default:
        check.add_pass(f"Default route sends AKS/app egress to Azure Firewall {cfg.firewall_ip}.")
    else:
        check.add_error(f"Expected default route to Azure Firewall was not found: {routes}")

    associated_subnets = " ".join(route_table.get("subnets") or []).lower()
    if "aks-subnet" in associated_subnets and "app-subnet" in associated_subnets:
        check.add_pass("Route table is associated with AKS and app subnets.")
    else:
        check.add_error(f"Route table is not associated with both AKS and app subnets: {route_table.get('subnets')}")

    return check


CHECKS: dict[str, tuple[str, Callable[[Azure], CheckResult]]] = {
    "1": ("No internet connection to compute", check_no_internet_to_compute),
    "2": ("Only connection via Application Gateway", check_app_gateway_only),
    "3": ("Networking only via VNet Peering", check_vnet_peering_only),
}


def print_result(check: CheckResult) -> None:
    header = f"{check.name}: {'PASS' if check.passed else 'FAIL'}"
    print()
    print(paint(header, Color.GREEN if check.passed else Color.RED))
    for detail in check.details:
        ok(detail)
    for error in check.errors:
        fail(error)


def run_checks(az: Azure, selections: list[str]) -> int:
    exit_code = 0
    for selection in selections:
        label, fn = CHECKS[selection]
        info(f"Running: {label}")
        try:
            check = fn(az)
        except ValidationError as exc:
            check = CheckResult(name=label, passed=False, errors=[str(exc)])
        except FileNotFoundError:
            check = CheckResult(name=label, passed=False, errors=["Azure CLI was not found on PATH. Install az and run az login."])
        print_result(check)
        if not check.passed:
            exit_code = 1
    return exit_code


def menu(az: Azure) -> int:
    while True:
        print()
        print(paint("Azure Network Security Validation", Color.BOLD + Color.BLUE if USE_COLOR else ""))
        print("1. Validate no direct internet connection to compute")
        print("2. Validate only inbound app path is Application Gateway")
        print("3. Validate networking path is VNet Peering only")
        print("4. Run all validations")
        print("q. Quit")
        choice = input(paint("Select an option: ", Color.CYAN)).strip().lower()
        if choice == "q":
            return 0
        if choice in CHECKS:
            run_checks(az, [choice])
            continue
        if choice == "4":
            return run_checks(az, ["1", "2", "3"])
        warn("Invalid selection. Choose 1, 2, 3, 4, or q.")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Validate Azure network security controls.")
    parser.add_argument("--environment", "-e", default="dev", choices=["dev", "qa", "prod"], help="Environment to validate.")
    parser.add_argument("--project-name", default="azure-hub-spoke-aks", help="Project name prefix.")
    parser.add_argument("--resource-group", help="Override resource group name.")
    parser.add_argument("--subscription-id", help="Azure subscription id. Defaults to current az account.")
    parser.add_argument("--expected-ingress-ip", help="Expected private nginx ingress IP.")
    parser.add_argument("--firewall-private-ip", help="Expected Azure Firewall private IP.")
    parser.add_argument("--all", action="store_true", help="Run all validations without showing the menu.")
    parser.add_argument(
        "--check",
        choices=["compute", "appgw", "peering"],
        action="append",
        help="Run one or more specific checks without showing the menu.",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    cfg = Config(
        environment=args.environment,
        project_name=args.project_name,
        subscription_id=args.subscription_id,
        resource_group=args.resource_group,
        expected_ingress_ip=args.expected_ingress_ip,
        firewall_private_ip=args.firewall_private_ip,
    )
    az = Azure(cfg)

    selected: list[str] = []
    if args.all:
        selected = ["1", "2", "3"]
    elif args.check:
        mapping = {"compute": "1", "appgw": "2", "peering": "3"}
        selected = [mapping[item] for item in args.check]

    if selected:
        return run_checks(az, selected)
    return menu(az)


if __name__ == "__main__":
    sys.exit(main())
