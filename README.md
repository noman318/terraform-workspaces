# Terraform Workspaces – EC2 per Environment

Provision one EC2 instance per environment (**dev**, **qa**, **prod**) from a single Terraform configuration, using [Terraform workspaces](https://developer.hashicorp.com/terraform/language/state/workspaces) to keep each environment's state separate.

The instance type is chosen automatically from the active workspace, and every instance is tagged with its environment name.

## Project Structure

```
terraform-workspaces/
├── main.tf                     # Root module: provider, variables, module call, output
├── module/
│   └── ec2_instance/
│       └── main.tf             # Reusable module: aws_instance + public_ip output
├── terraform.tfvars.example    # Template for your variable values
├── .terraform.lock.hcl         # Provider version lock (committed)
├── .gitignore                  # Ignores state, .terraform/, and real *.tfvars
└── README.md
```

Generated locally and **not** committed:

```
├── .terraform/                 # Provider plugins (terraform init)
├── terraform.tfstate           # State for the "default" workspace
├── terraform.tfstate.d/        # State for each named workspace
│   ├── dev/
│   ├── qa/
│   └── prod/
└── terraform.tfvars            # Your real values (copied from the example)
```

## How It Works

The root `main.tf` maps each workspace to an instance type:

| Workspace | Instance type |
|---|---|
| `dev` | `t2.small` |
| `qa` | `t3.micro` |
| `prod` | `c7i-flex.large` |
| anything else (incl. `default`) | `t2.small` (fallback) |

```hcl
instance_type = lookup(var.instance_type, terraform.workspace, "t2.small")
```

The `ec2_instance` module creates the instance with:

- a public IP (`associate_public_ip_address = true`)
- a `Name` tag of `ec2-<workspace>` (e.g. `ec2-dev`, `ec2-prod`)

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) installed
- AWS credentials configured (`aws configure` or environment variables)
- An existing **subnet** in `ap-south-1` with a route `0.0.0.0/0` to an Internet Gateway (needed for the public IP to be reachable)
- An x86_64 **AMI** ID available in `ap-south-1`

## Inputs

| Variable | Description | Set in |
|---|---|---|
| `ami` | AMI ID for the instance | `terraform.tfvars` |
| `subnet` | Subnet ID to launch into | `terraform.tfvars` |
| `instance_type` | Map of workspace → instance type | `main.tf` (default) |

## Outputs

| Output | Description |
|---|---|
| `public_ip` | Public IP of the instance in the current workspace |

## Usage

```bash
# 1. Set your values
cp terraform.tfvars.example terraform.tfvars   # then edit ami and subnet

# 2. Download the AWS provider
terraform init

# 3. Create (or switch to) a workspace
terraform workspace new dev        # first time
terraform workspace select dev     # afterwards

# 4. Preview and apply
terraform plan
terraform apply

# 5. Get the public IP
terraform output public_ip
```

Repeat steps 3–5 with `qa` and `prod` to create the other environments. Each workspace has its own state, so applying in one never touches the others.

## Workspace Commands

```bash
terraform workspace show            # current workspace
terraform workspace list            # all workspaces (* = current)
terraform workspace select default  # go back to the default workspace
```

## Clean Up

Destroy each environment's resources, then delete its workspace:

```bash
terraform workspace select dev
terraform destroy
terraform workspace select default
terraform workspace delete dev
```

You cannot delete the workspace you are currently in, and Terraform refuses to delete a workspace whose state still tracks resources.

## Free Tier Notes

Free tier eligibility depends on your AWS account. To list the instance types your account can launch for free:

```bash
aws ec2 describe-instance-types \
  --filters Name=free-tier-eligible,Values=true \
  --query "InstanceTypes[].InstanceType" \
  --region ap-south-1
```

Accounts on the new AWS Free plan (created on or after 15 Jul 2025) do **not** include `t2` types. Launching `t2.small` there fails with `InvalidParameterCombination: The specified instance type is not eligible for Free Tier`. Change the `dev` entry and the fallback in `main.tf` to an eligible type such as `t3.micro` or `t3.small`.
