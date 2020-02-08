# AWS ECS

This repository contains the Terraform modules for creating a production ready ECS in AWS.

## Getting Started

Using a [homebrew]() to install my dependencies.


| Component| Notes|
| :--------|:-----|
|[aws]()| aws cli|
|[terraform]()| to provision infrastructure as code|
|[tfswitch]() | switching between multiple versions of terraform|
| [pre-commit]() | runs commands as ci on pre commits|

#### Pre-requisits

Make sure you have pre-commit installed before you start commiting code

```bash
pre-commit install
```

### AWS Credentials

to setup the aws credentials you need to run the following command.
Make sure you obtain an Access Key and a Secret before you do this.

```bash
mkdir .aws && cat <<EOF>> ./.aws/.secrets.env
export AWS_ACCESS_KEY_ID=YOUR_KEY
export AWS_SECRET_ACCESS_KEY=YOUR_SECRET
EOF
```

### Using Make to run commands

Use make to initiate a terraform plan

```bash
make init -env=${ENVIRONEMNT} 
```

#### Available Commands:

```bash
make init  -env=${ENVIRONEMNT} 
make plan  -env=${ENVIRONEMNT} 
make apply -env=${ENVIRONEMNT} 
make clean -env=${ENVIRONEMNT} 
```

PS: Do not remove the Route 53 as it's manually created, and it's used to automatically attach an application load balancer.

####  Available Environments:

| Key        | Description |
| -----      |------|
| dev        | Development |
| staging    | Staging |
| production | Production |  


####  Conventions

These are the conventions we have in every module:

* Contains main.tf where all the terraform code is
* If main.tf is too big we create more *.tf files with proper names
* [Optional] Contains outputs.tf with the output parameters
* [Optional] Contains variables.tf which sets required attributes
* For grouping in AWS we set the tag "Environment" everywhere where possible

---

####  ECS infrastructure

As stated above, ECS needs EC2 instances that are used to run Docker containers on. To do so you need infrastructure for this. Here is an ECS production-ready infrastructure diagram.



![ECS infra](img/aws-solution-design.jpg)

