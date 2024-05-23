## Description

This terraform and tests are part of CI with github-actions. But here a small procedure to use it manually.

The puropse of this CI is to test the integration between RKE2, longhorn, rancher and neuvector.

## Prerequis

On Digital Ocean account:

- generate a PAT (private access token)
- a set of SSH key
- Create a Space with a an acces_key and a secret key

Add inside ./test a file .key with the private ssh key generate by DO.

## Create/delete a bucket to store backend

```bash
export DO_PAT="dop_v1_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"

# info
s3cmd ls
s3cmd info s3://github-action-8147167750

# create
s3cmd mb s3://github-action-8147167750

# delete
s3cmd rb s3://github-action-8147167750 --recursive

# with terraform
cd ./test/DO/backend
terraform init
terraform plan -out=terraform.tfplan \
-var "GITHUB_RUN_ID=${GITHUB_RUN_ID}" \
-var "do_token=${DO_PAT}" \
-var "spaces_access_key_id=${AWS_ACCESS_KEY_ID}" \
-var "spaces_access_key_secret=${AWS_SECRET_ACCESS_KEY}"
```

## Create an infra

```bash
export DO_PAT="dop_v1_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"

##
# init with backend config
terraform init --backend-config=./backend_config.hcl
# ./backend_config.hcl
# bucket="name"
# access_key="<YOUR ACCESS KEY CONFIGURED AT STEP 1.2 Space Access Keys from the Tutorial>"
# secret_key="<YOUR SECURE KEY CONFIGURED AT STEP 1.2 Space Access Keys from the Tutorial>"

# init with one line command
terraform init \
-backend-config="access_key=$SPACES_ACCESS_TOKEN" \
-backend-config="secret_key=$SPACES_SECRET_KEY" \
-backend-config="bucket=terraform-backend-github"

# recommended method
export AWS_ACCESS_KEY_ID=DOxxxxxxxxxxxxxxxx
export AWS_SECRET_ACCESS_KEY=xxxxxxxxxxxxxxxxxx
terraform init -backend-config="bucket=terraform-backend-rkub-quickstart"

# auto-approve (default: size=s-1vcpu-1gb, 1 controller + 2 workers)
terraform apply -var "GITHUB_RUN_ID=${GITHUB_RUN_ID}" -var "do_token=${DO_PAT}" -auto-approve

# Deploy
terraform plan -destroy -out=terraform.tfplan \
-var "GITHUB_RUN_ID=${GITHUB_RUN_ID}" \
-var "do_token=${DO_PAT}" \
-var "do_worker_count=0" \
-var "do_controller_count=1" \
-var "do_instance_size=s-1vcpu-1gb" \
-var "spaces_access_key_id=${AWS_ACCESS_KEY_ID}" \
-var "spaces_access_key_secret=${AWS_SECRET_ACCESS_KEY}"

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
```

## Use Workspace

```bash
# Create a workspace
export GITHUB_RUN_ID="777"
terraform workspace new rkub-${GITHUB_RUN_ID}

# Get back to a workspace
terraform workspace select rkub-${GITHUB_RUN_ID}

# Delete Workspace
terraform workspace select default
terraform workspace delete rkub-${GITHUB_RUN_ID}
```
