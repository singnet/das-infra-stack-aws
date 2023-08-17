# das-infra-stack-aws
Scripts/assets to install required infrastructure stack in AWS

## Objective:

This repository is about deployment of especific version functions to AWS Lambda functions (The images storaged in AWS S3 bucket)
## resources:
- Lambda Functions (see config.tfvars)
- EC2 instance (Temporary test)

## Configuration

Copy the `secret.tf.example` file to `secret.tf`:

- Configure the Terraform S3 backend by adding the `AWS_ACCESS_KEY` and `AWS_SECRET_KEY` of the `tfstate` user.

## Configuration

Copy the `secret.tf.example` file to `secret.tf`:

- Configure the Terraform S3 backend by adding the `AWS_ACCESS_KEY` and `AWS_SECRET_KEY` of the `tfstate` user.

```shell
# init providers and backend
terraform init

# check configuration files format
terraform fmt -check -diff -recursive .

# format configuration files
terraform fmt -diff -recursive .

# validate configuration
terraform validate
```

## Create/update stack

Notes:

- If you update the `ssh_key_ids` configuration, the instances will be **replaced**.
- If you update a installation script, the corresponding instance will be **replaced**.

```shell
# plan
terraform plan -var-file=config.tfvars -out tfplan

# apply
terraform apply tfplan
```
## Destroy stack

```shell
# plan destroy
terraform plan -destroy -var-file=config.tfvars -out tfplan-destroy

# apply destroy
terraform apply tfplan-destroy
```
