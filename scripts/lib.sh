#!/usr/bin/env bash

resolve_terraform() {
  if [[ -n "${TERRAFORM_BIN:-}" ]]; then
    echo "${TERRAFORM_BIN}"
    return 0
  fi

  if command -v terraform >/dev/null 2>&1; then
    command -v terraform
    return 0
  fi

  if command -v terraform.exe >/dev/null 2>&1; then
    command -v terraform.exe
    return 0
  fi

  echo "terraform is not installed or not on PATH. Set TERRAFORM_BIN to the Terraform executable." >&2
  return 127
}
