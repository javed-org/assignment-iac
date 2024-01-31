# Terraform Infrastructure Provisioning with GitHub Actions

This repository contains Terraform code organized into modular components to provision infrastructure on AWS. The infrastructure includes VPC, ECR, and EKS, each implemented as a separate Terraform module.

## Project Structure

- **modules/vpc:** Defines the Virtual Private Cloud (VPC) configuration.
- **modules/ecr:** Manages the Elastic Container Registry (ECR) for Docker image storage.
- **modules/eks:** Sets up the Elastic Kubernetes Service (EKS) cluster.

## GitHub Actions Workflows

### Provision Infrastructure Workflow

The infrastructure provisioning is automated through GitHub Actions. The workflow is triggered on pushes to the `main` branch.

```yaml
name: Provision 
on:
  push:
    branches:
      - main 
```

### Terraform Plan:
- Initializes Terraform.
- Validates the configuration.
- Generates a plan.

### Terraform Apply:
Applies the Terraform plan to provision infrastructure.
AWS resources like VPC, RDS, ECR, and EKS are created.

# Usage
1. On pull request plan workflow will execute automatically
2. On push changes to the main branch apply workflow will apply changes to the infra.

### Steps to exectute the terraform code and setup environment:
##### Step 1: Create GitHub OIDC Provider

1. Open the [IAM console](https://console.aws.amazon.com/iam/).
2. Navigate to "Identity providers."
3. Add a new "OpenID Connect" provider with URL `https://token.actions.githubusercontent.com`.
4. Obtain the thumbprint for certificate verification.
5. Set "Audience" as `sts.amazonaws.com`.
6. Verify and add the provider.

##### Step 2: Create IAM Role

1. In IAM console, assign a role for the new IdP.
2. Create a new role, choose "Web identity," and set "Audience" to `sts.amazonaws.com`.
3. Provide the organization name
4. Name the role (e.g., `aws-role-name`).

##### Step 4: Create a S3 bucket manually for remote state management
**NOTE:** Make sure bucket region should be same as of the region varible for the infra setup
##### Step 5: Updae the secrets in github repo settings as below:
```
TF_REMOTE_STATE_BUCKET=your-bucket-name
AWS_REGION=region-name
AWS_ROLE_ARN=aws-role-arn
```
