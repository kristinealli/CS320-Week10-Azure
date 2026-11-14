# CS320 Azure WordPress Deployment

This repository provisions an Azure Linux VM with Ansible and deploys WordPress
using the `stack_install`, `stack_config`, and `wordpress` roles.

## Prerequisites

- An active Azure for Students subscription
- Azure CLI logged in to the correct tenant and subscription
- Ansible and the required Python packages
- An SSH key pair at the paths configured in `vars/azure.yml`
- A local Ansible Vault password file

Install the Ansible collections with:

```bash
ansible-galaxy collection install -r requirements.yml
```

Confirm Azure access before provisioning:

```bash
az account show
ansible-playbook test.azure.yml
```

Do not commit Azure credentials, the Vault password, private SSH keys, or
unencrypted secret files. The repository ignores local Vault password files and
SSH key material. The encrypted values used by the roles are in
`group_vars/all/vault.yml`.

## Required variables

Infrastructure values are defined in `vars/azure.yml`, including:

- Azure location and resource names
- VM size and Ubuntu image
- SSH public/private key paths
- The allowed SSH source CIDR

WordPress and database settings are in `group_vars/all/main.yml`. The
administrator email, WordPress administrator password, and database password
are encrypted in `group_vars/all/vault.yml`.

Create or update the encrypted variables with Ansible Vault:

```bash
ansible-vault edit group_vars/all/vault.yml
```

The inventory public IP in `inventory.ini` must match the provisioned Azure
public IP before running the deployment playbook.

## Deploy

Provision the Azure resources:

```bash
ansible-playbook provision.yml
```

Deploy WordPress:

```bash
ansible-playbook --ask-vault-pass deploy.yml
```

After provisioning, update `inventory.ini` if the public IP changed. The site
is available at:

```text
http://<public-ip>/
```

## Verify the deployment

Run the verification playbook after deployment:

```bash
ansible-playbook --ask-vault-pass verify.yml
```

Verification checks:

- The Azure resource group and expected resources exist
- SSH and HTTP are reachable
- NGINX, PHP-FPM, and MariaDB are enabled and running
- WordPress is installed
- The HTTP response contains WordPress content

## Test idempotence

The idempotence test runs provisioning and deployment twice. It saves both
passes under `evidence/` and fails if the second provisioning or deployment
pass reports any changed tasks:

```bash
./test-idempotence.sh
```

The script uses `VAULT_PASSWORD_FILE` when set; otherwise it expects the local
ignored file `.vault-password`.

## Remove Azure resources

Remove the resource group and everything created for this assignment:

```bash
az group delete --name cs320-week10-rg --yes --no-wait
```

Wait for deletion to complete, then verify:

```bash
az group exists --name cs320-week10-rg
```

The command should return `false`. Also confirm in the Azure portal that the
resource group and its resources are gone so they no longer consume 
credit.

Store deployment output, the second idempotence pass, verification output, and
resource-removal evidence in `evidence/`. Do not include passwords, Vault
passwords, private keys, or access tokens. 
