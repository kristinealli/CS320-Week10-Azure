#!/usr/bin/env bash
set -euo pipefail

evidence_dir="evidence"
vault_password_file="${VAULT_PASSWORD_FILE:-.vault-password}"

if ! command -v ansible-playbook >/dev/null 2>&1; then
  echo "ansible-playbook is required but was not found." >&2
  exit 1
fi

if [[ ! -f "$vault_password_file" ]]; then
  echo "Vault password file not found: $vault_password_file" >&2
  echo "Set VAULT_PASSWORD_FILE or create the ignored .vault-password file." >&2
  exit 1
fi

mkdir -p "$evidence_dir"

run_playbook() {
  local playbook="$1"
  local output="$2"
  ansible-playbook \
    --vault-password-file "$vault_password_file" \
    "$playbook" | tee "$output"
}

assert_no_changes() {
  local output="$1"
  if ! grep -Eq 'changed=0[[:space:]]+unreachable=0[[:space:]]+failed=0' "$output"; then
    echo "Idempotence check failed; the second pass reported changes or errors." >&2
    exit 1
  fi
}

run_playbook provision.yml evidence/idempotence-provision-pass-1.txt
run_playbook deploy.yml evidence/idempotence-deploy-pass-1.txt
run_playbook provision.yml evidence/idempotence-provision-pass-2.txt
assert_no_changes evidence/idempotence-provision-pass-2.txt
run_playbook deploy.yml evidence/idempotence-deploy-pass-2.txt
assert_no_changes evidence/idempotence-deploy-pass-2.txt

echo "Idempotence verification passed."
