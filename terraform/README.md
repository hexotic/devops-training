# Terraform

1. Deploy resources
2. Dynamic deployments
3. Terraform Provisioners
4. Remote management
5. Module
6. Mini-project

# Intro


* Create instances for tests (CI)
* Create and prepare machines for deployment (CD)

It's a provisioning tool (like CloudFormation)
(Ansible is a conf management and Docker is server templating)

IaC:
* code reuse
* code evolution
* collaboration

Why Terraform:
* multi cloud providers
* free
* easy to read language
* extension
* integrate with Conf Mgmt tools

Providers
* official: aws, gcp, azur...
* verifier bigfip, heroky, ...
* community ucloud, ...

Only official and verified providers will be installed by Terraform when needed.

## Installation
Local install from https://www.terraform.io/downloads

Require programatic access to AWS

# Deploy resources
```
<block> <parameters> {
    key1 = value1
    key2 = value2
}
```

## HCL language
Example:
```HCL
block name
   |     resource type: local=provider,
   |        |           file=resource
   |        |         resource name (terraform)
   |        |           |
resource "local_file" "foo" {
    filename = "/tmp/foo.txt"  > arguments
    content = "foo bar"        >
}
```

Init -> plan <-> apply -> destroy
```sh
terraform init
terraform plan
terraform apply
terraform destroy
```

## Project structure
Project directory: contains terraform files
```
main.tf         main config
variables.tf    var declarations
outputs.tf      output from rsc
provider.tf     provider definition
```

`terraform.tfstate`: contains all Terraform information and sensitive data<br>
NOT TO BE PUT IN GIT

## TP2 deploy resource

terraform init
terraform plan
terraform apply
terraform apply -auto-approve

## Deploy on EC2
```
provider "aws" {
    region   = "us-west-2"
    access_key = ""
    secret_key = ""
}

resource "aws_instance" myec2 {
    ami = "ami-082b5a644766e0e6f"
    instance_type = "t2.micro"
}
```

## TP3 deploy EC2

https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance

<details>
<summary>
<code>ec2.tf</code>
</summary>

```
resource "aws_instance" "myec2" {
  tags = {
    "Name" = "chris-ec2-terraform",
    "formation" = "Frazer",
    iac = "terraform"
  }
  key_name = "christophe-kp"
  ami = "ami-04505e74c0741db8d"
  instance_type = "t2.micro"
}
```
</details>

<details>
<summary><code>provider.tf</code></summary>
```
provider "aws" {
    region = "us-east-1"
    access_key = "XXX"
    secret_key = "XXX"
}
```
</details>

# Dynamic deployments

## Variables
Variables located in `variables.tf`

### Example 1

```sh
variable "filename" {
    default = "/tmp/foo.txt"
    type = string   # not mandatory
    description = "path of file"
}
```

### Example 2
```sh
variable "greetings" {
    default = [ "Mr", "Mrs", "Sir" ]
    type = list
}
resource "foo" "bar" {
    prefix = var.greetings[0]
} 
```

## Possible types

<code>string | number | bool | any | list | map |object | tuple</code>

## Override
Values in `variables.tf`
overriden 
* in `terraform.tfvars` (syntax is different)
```
timeout="400"
az = [ "us-east1-a"]
```
* env var: `export TF_VAR_<var name>`
* `terraform plan|apply -var="instancetype=t2.micro"`

## Variable definition precedence
Increasing priority:
* env var
* `terraform.tfvars`
* `*.auto.tfvars` (alphabetical order)
* `-var` or `--var-file` (command line)


## Attributes

NOTE: stringification with : `${local_file.foo.content}`

### Example 1
```
resource "local_file" "foo" {
  content = "This is foo"
}

resource "local_file" "bar" {
  content = "bar: ${local_file.foo.content}"
}
```

### Attributes
```sh
output {
    value = local_file.foo.id
    description = "record the value...." # opt
}
```

### Dependencies

* implicit dependencies: detected by terraform
* explicit dependencies: use keyword `depends_on = [ aws_instance.myec2 ]`

## TP5 EC2 and attibutes
Create a file with EC2 data:

```sh
resource "local_file" "ec2outputfile" {
  filename = "./ec2-parameters.txt"
  content = "This EC2 type: ${aws_instance.myec2.instance_type} - ami: ${aws_instance.myec2.ami}"
}
```

-----

# Excerpts
```
output "my_ip" {
  value = aws_instance.myec2.public_ip
}
resource "aws_instance" "myec2 {
    instance_type = "t2.micro"
}

resource "local_file" "ec2out" {
    filename = "./ec2-param.txt"
    content = "ec2: ${aws_instance.ec2.ami}"
}
```

# Commands recap
```sh
terraform init
terraform plan
terraform apply -auto-approve
terraform destroy

terraform fmt

terraform output
terraform output file_id # output "file_id" {}
```