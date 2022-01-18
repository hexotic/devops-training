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

## Credentials
* in Terraform file:<br>
`access_key = "XXXXX"`<br>
`secret_key = "XXXXX"`
* `shared_credentials_file =`
```
[default]
aws_access_key_id     = ""
aws_secret_access_key = ""
```
* Env variables
```sh
export AWS_ACCESS_KEY_ID=""
export AWS_SECRET_ACCESS_KEY=""
export AWS_DEFAULT_REGION="us-east-1"
```

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

## Data source
Use source that was not created by Terraform.
<br>
Ex: create EC2 from a EC2 created manually
<br>
Keyword: `data`
```
data "local_file" "foo" {
    filename = "/etc/foo.txt"
}

resource "local_file" "bar" {
    filename = "/etc/bar.txt"
    content = data.local_file.foo.content
}
```

## TP6 deploy EC2 with data in file
```ruby
resource "aws_instance" "myec2" {
  tags = {
    Name      = "chris-ec2-terraform",
    formation = "Frazer",
    iac       = "terraform"
  }
  key_name      = "christophe-kp"
  ami           = var.ami
  instance_type = data.local_file.ec2_info.content
}

data "local_file" "ec2_info" {
  filename = "./infos.txt"
}
```

## TP7 deploy EC2 with SG
https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance#security_groups

# Provisioners
https://www.terraform.io/language/resources/provisioners

* `provisioner "local-exec"`
* `provisioner "remote-exec"`
  * `connection {}`

-----
### user_data
```
resource "aws_instance" "myec2" {
  user_data = <<-EOF
#!/bin/bash
sudo apt update
EOF
}
```

-----
# Provisioners

EC2 -> EIP (with ID EC2)
/!\ local provisioner with temp public IP (self.public_ip) while EIP is created.
<br>Solution: local provisioner with ip of EIP 
<br>
But: Cyclic dependency<br>
=> Create association

## TP8 EC2 with nginx 
user_data and provisioner

## TP8 bis wordpress deployment with ansible
It's possible to add a variable to `hosts` or host ip so it's easier to change it on the command line. (localhost, 127.0.0.1)

# Remote management
It's possible to store `.tfstate` in the cloud (like S3).

```
terraform {
  backend "s3" {
    bucket     = "chris-bucket-ajc"
    key        = "tp9.tfstate"
    region     = "us-east-1"
    access_key = "XXXXX"
    secret_key = "XXXXX"
  }
}
```

## TP9

# Modules

## Example
```
terraform-projects
├── modules
│   └── payroll-app
└── payroll-app
    ├── main.tf
    └── provider.tf
```
`main.tf`
```
module "us_payroll" {
  source = "../modules/payroll-app"
  app-region = "us-east-1"
  ami = "ami-24e...."
}
```

```
terraform-projects
├── Dev
│   └── jenkins.tfvars
│   └── main.tf
│   └── variable.tf
└── Module
    └── ECS
    ├── main.tf
        └── output.tf
        └── variable.tf
    └── Networking
        ├── main.tf
        └── output.tf
        └── variable.tf
```

## Module registry
https://registry.terraform.io/

https://www.terraform.io/language/modules/sources#github


-----


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