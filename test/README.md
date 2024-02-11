## Description

This terraform and tests are part of CI with github-actions. But here a small procedure to use it manually.

The puropse of this CI is to test the integration between RKE2, longhorn, rancher and neuvector.

## Prerequis

On Digital Ocean account:
- generate a PAT (private access token)
- a set of SSH key

Add inside ./test a file .key with the private ssh key generate by DO.

```bash
export DO_PAT="dop_v1_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"

# Create 3 VMs
terraform init
terraform plan -out=terraform.tfplan -var "do_token=${DO_PAT}"
terraform apply terraform.tfplan

# auto-approve
terraform apply -var "GITHUB_RUN_ID=777" -var "do_token=${DO_PAT}" -auto-approve

# More options
terraform apply -var "GITHUB_RUN_ID=777" \
-var "do_token=${DO_PAT}" \
-var "do_worker_count=0" \
-var "do_controller_count=3" \
-var "do_instance_size=s-2vcpu-4gb" \
-auto-approve

# connect to a controller
ssh root@$(terraform output -json ip_address_controllers | jq -r '.[0]') -i .key

# connect to a worker
ssh root@$(terraform output -json ip_address_workers | jq -r '.[0]') -i .key

# Destroy
terraform plan -destroy -out=terraform.tfplan -var "GITHUB_RUN_ID=777" \
-var "do_token=${DO_PAT}" \
-var "do_worker_count=0" \
-var "do_controller_count=3" \
-var "do_instance_size=s-2vcpu-4gb"
terraform apply terraform.tfplan
```
