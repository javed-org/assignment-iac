# Terraform Infrastructure Provisioning with GitHub Actions

This repository contains Terraform code organized into modular components to provision infrastructure on AWS. The infrastructure includes VPC, RDS, ECR, and EKS, each implemented as a separate Terraform module.

## Project Structure

- **modules/vpc:** Defines the Virtual Private Cloud (VPC) configuration.
- **modules/ecr:** Manages the Elastic Container Registry (ECR) for Docker image storage.
- **modules/eks:** Sets up the Elastic Kubernetes Service (EKS) cluster.
## Prerequisite
1. Create a S3 bucket manually for remote state management
2. Create IAM Role for terraform provisioning (check customization section :arrow_down: )
3. Updae the secrets in github settings(TF_REMOTE_STATE_BUCKET,AWS_REGION,AWS_ROLE_ARN)


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
# Workflow Steps

### Checkout Code:

Clones the repository and checks out the source code.

### Configure AWS Credentials:

Uses the AWS CLI to configure AWS credentials, assuming the IAM role for Terraform.

### Setup Terraform:

Sets up Terraform with the specified version and environment variables.

### Terraform Plan:

- Initializes Terraform.
- Validates the configuration.
- Generates a plan.

### Terraform Apply:

Applies the Terraform plan to provision infrastructure.
AWS resources like VPC, RDS, ECR, and EKS are created.

# Usage

1. Push changes to the main branch.
2. Terraform plan is generated and applied automatically.

# Notes

- The Terraform code is organized into modules for better maintainability.
- IAM role `assignment-terraform-1` is assumed for configuring AWS credentials.
- AWS region is set to `eu-west-1`.
- The Terraform state is stored remotely using the key `${{ env.BRANCH_NAME }}/terraform.tfstate`.

# Customization

- Customize IAM roles, AWS region,S3 bucket for remote state management and other parameters in GitHub Actions workflow files based on your AWS setup.
- Adjust Terraform code and configurations in modules as needed for your specific infrastructure requirements.
- To authenticate with AWS IAM Role is needed below are the steps to create Role:

## GitHub OIDC Provider Setup for AWS IAM

This guide helps set up a GitHub OIDC provider in AWS IAM and create the necessary IAM role with a trust policy.

### Step 1: Create GitHub OIDC Provider

1. Open the [IAM console](https://console.aws.amazon.com/iam/).
2. Navigate to "Identity providers."
3. Add a new "OpenID Connect" provider with URL `https://token.actions.githubusercontent.com`.
4. Obtain the thumbprint for certificate verification.
5. Set "Audience" as `sts.amazonaws.com`.
6. Verify and add the provider.

### Step 2: Create IAM Role

1. In IAM console, assign a role for the new IdP.
2. Create a new role, choose "Web identity," and set "Audience" to `sts.amazonaws.com`.
3. Name the role (e.g., `GitHubAction-AssumeRoleWithAction`).

### Step 3: Configure Trust Policy

1. Open the role in IAM console.
2. Edit trust relationship, allowing your GitHub organization, repository, and branch with this JSON snippet:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "<GitHub IdP ARN>"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    "token.actions.githubusercontent.com:sub": "repo: <githubOrg/reponame>:*",
                    "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
                }
            }
        }
    ]
}

