## Description

This terraform and tests are part of CI with github-actions. But here a small procedure to use it manually.

The puropse of this CI is to test the integration between RKE2, longhorn, rancher and neuvector.

## Prerequis

On Digital Ocean account:
- generate a PAT (private access token)
- a set of SSH key
- Create a Space with a an acces_key and a secret key

Add inside ./test a file .key with the private ssh key generate by DO.

```bash
export DO_PAT="dop_v1_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"

# init with backend config
terraform init --backend-config=./backend_config.hcl
# ./backend_config.hcl
# access_key="<YOUR ACCESS KEY CONFIGURED AT STEP 1.2 Space Access Keys from the Tutorial>"
# secret_key="<YOUR SECURE KEY CONFIGURED AT STEP 1.2 Space Access Keys from the Tutorial>"

# init with one line command
terraform init \
-backend-config="access_key=$SPACES_ACCESS_TOKEN" \
-backend-config="secret_key=$SPACES_SECRET_KEY" \

# recommended method
export AWS_ACCESS_KEY_ID=DOxxxxxxxxxxxxxxxx
export AWS_SECRET_ACCESS_KEY=xxxxxxxxxxxxxxxxxx
terraform init

# Create a workspace
export GITHUB_RUN_ID="777"
terraform workspace new rkub-${GITHUB_RUN_ID}

# Get back to a workspace
terraform workspace select rkub-${GITHUB_RUN_ID}

# auto-approve (default: size=s-1vcpu-1gb, 1 controller + 2 workers)
terraform apply -var "GITHUB_RUN_ID=${GITHUB_RUN_ID}" -var "do_token=${DO_PAT}" -auto-approve

# Deploy
terraform plan -out=terraform.tfplan \
-var "GITHUB_RUN_ID=${GITHUB_RUN_ID}" \
-var "do_token=${DO_PAT}" \
-var "do_worker_count=1" \
-var "do_controller_count=3" \
-var "do_instance_size=s-1vcpu-1gb"

# Apply
terraform apply terraform.tfplan

# Reconciliate
terraform plan -refresh-only -out=terraform.tfplan \
-var "GITHUB_RUN_ID=${GITHUB_RUN_ID}" \
-var "do_token=${DO_PAT}" \
-var "do_worker_count=1" \
-var "do_controller_count=3" \
-var "do_instance_size=s-1vcpu-1gb"

# connect to a controller
ssh root@$(terraform output -json ip_address_controllers | jq -r '.[0]') -i .key

# connect to a worker
ssh root@$(terraform output -json ip_address_workers | jq -r '.[0]') -i .key

# Destroy
terraform plan -destroy -out=terraform.tfplan \
-var "GITHUB_RUN_ID=${GITHUB_RUN_ID}" \
-var "do_token=${DO_PAT}" \
-var "do_worker_count=1" \
-var "do_controller_count=3" \
-var "do_instance_size=s-1vcpu-1gb"
# Apply destroy
terraform apply terraform.tfplan

# Delete Workspace
terraform workspace select default
terraform workspace delete rkub-${GITHUB_RUN_ID}
```
