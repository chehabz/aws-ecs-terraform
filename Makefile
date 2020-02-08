SHELL := /bin/bash

setup:
	source ./.aws/.secrets.env

init: setup
	terraform init  --backend=true -backend-config="./env/$(env)/backend.conf"
	terraform get

plan:
	terraform fmt
	terraform validate
	terraform plan --var-file="./env/$(env)/values.tfvars" -out "$(env).tfplan"

apply:
	terraform apply --auto-approve=true -compact-warnings "$(env).tfplan"
	rm -rf *.tfplan

refresh: setup
	terraform refresh --var-file="./env/$(env)/values.tfvars"

clean:
	terraform destroy --var-file="./env/$(env)/values.tfvars" --auto-approve=true

switch ws: setup
	terraform workspace select $(env)

benchmark:
    
	wrk -t20 -c500 -d30s --latency https://service-name.$(env).com

importdb:
	./scripts/import.sh $(env) $(shell terraform output db_password) $(shell terraform output db_endpoint) 