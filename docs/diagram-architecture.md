# Diagram Architecture

This document explains the project architecture with Mermaid diagrams. The
platform uses Terraform for Azure infrastructure and Helm for Kubernetes
application releases.

## High-Level Architecture

```mermaid
flowchart TB
    user[External User]
    internet((Internet))
    appgw[Application Gateway WAF<br/>Public IP]

    subgraph hub[Hub VNet]
        appgw
        firewall[Azure Firewall<br/>Private IP 10.0.0.4]
        bastion[Azure Bastion]
        shared[Shared Services Subnet]
    end

    subgraph spoke[Spoke VNet]
        aksSubnet[AKS Subnet]
        appSubnet[App Subnet]
        peSubnet[Private Endpoint Subnet]
        kvpe[Key Vault Private Endpoint]

        subgraph aks[Private AKS Cluster]
            ingress[nginx Ingress Controller<br/>Internal LB 10.10.1.100]
            svc[hello-world ClusterIP Service]
            pods[Paz-Idan nginx Pods]
        end
    end

    kv[Azure Key Vault<br/>Public Access Disabled]
    law[Log Analytics Workspace]
    state[Azure Storage<br/>Terraform Remote State]
    terraform[Terraform CLI / CI]

    user --> internet --> appgw
    appgw --> ingress
    ingress --> svc --> pods

    hub <-->|VNet Peering| spoke
    aksSubnet -->|UDR 0.0.0.0/0| firewall
    appSubnet -->|UDR 0.0.0.0/0| firewall
    kvpe --> kv
    aks --> law
    kv --> law
    terraform -. uses .-> state
```

## Traffic Flow

```mermaid
sequenceDiagram
    participant User as User Browser
    participant AGW as Application Gateway WAF
    participant NGINX as Internal nginx Ingress
    participant SVC as hello-world Service
    participant POD as Paz-Idan Pods

    User->>AGW: HTTP request to hello-world.local
    AGW->>NGINX: Forward to 10.10.1.100:80
    NGINX->>SVC: Route path /
    SVC->>POD: Load balance to nginx pod
    POD-->>SVC: HTML response
    SVC-->>NGINX: HTTP 200
    NGINX-->>AGW: HTTP 200
    AGW-->>User: Paz-Idan website
```

## Deployment Ownership

```mermaid
flowchart LR
    terraform[Terraform]
    helmIngress[Helm<br/>ingress-nginx upstream chart]
    helmApp[Helm<br/>charts/hello-world]

    terraform --> rg[Resource Group]
    terraform --> network[Hub/Spoke VNets<br/>Subnets, NSGs, Peering, UDR]
    terraform --> security[Application Gateway WAF<br/>Azure Firewall<br/>Key Vault]
    terraform --> aks[Private AKS]
    terraform --> state[Remote State Storage]

    helmIngress --> ingress[nginx Ingress Controller<br/>Internal Load Balancer]
    helmApp --> app[ConfigMap, Deployment,<br/>Service, Ingress]
```

## Security Control Points

```mermaid
flowchart TB
    public[Public Internet]
    agw[Only Public App Entry<br/>Application Gateway WAF]
    privateAks[Private AKS API]
    nodes[AKS Nodes<br/>No Public IPs]
    internalLb[Internal Load Balancer Only]
    nsg[Spoke NSGs<br/>Deny Internet Inbound]
    udr[UDR Default Route]
    afw[Azure Firewall]
    pe[Private Endpoint]
    kv[Key Vault<br/>Public Access Disabled]

    public --> agw
    agw --> internalLb
    internalLb --> nodes
    privateAks -. not internet reachable .- nodes
    nsg --> nodes
    nodes --> udr --> afw
    pe --> kv
```

## Explanation

The platform is built around a private workload model. The public internet can
reach only Application Gateway WAF. Application Gateway forwards traffic to the
private nginx ingress load balancer inside the spoke VNet. nginx ingress routes
the request to the `hello-world` ClusterIP service, which then sends traffic to
the `Paz-Idan` nginx pods.

The AKS API is private, AKS nodes have no public IP addresses, and Kubernetes
does not expose a public load balancer. Spoke subnet NSGs deny inbound internet
traffic. AKS and app subnet egress use a default route to Azure Firewall.

Hub and Spoke communicate through VNet peering only in the default design. The
project does not deploy VPN gateways, ExpressRoute circuits, or NAT gateways.

Key Vault is private-first: public access is disabled, a private endpoint is
deployed in the spoke private endpoint subnet, private DNS is linked to the
spoke VNet, and diagnostics are sent to Log Analytics.

Terraform owns Azure infrastructure. Helm owns Kubernetes app releases. This
keeps cloud resource lifecycle and application rollout lifecycle separate and
easier to operate.
