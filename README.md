# About
This Terraform Code sets up the Vault Infrastructure with Consul as the Backend for HA. We use Terragrunt as a wrapper to our terraform code to put dependencies between folders and execute all folders

# Terragrunt

More information on terragrunt can be found in https://github.com/gruntwork-io/terragrunt

# How is it structured

* Code is separated into folders based on its function and requirement
* Each folder contains remotestate.tf, terraform.tfvars, output.tf and variables.tf by Default
    * remotestate.tf - Contains Remote State definition of Terraform
    * terraform.tfvars - Contains Terragrunt Dependency definitions
    * variables.tf - Contains all required Variable definitions for Terraform
    * output.tf - Contains all output definitions for Terraform
* Apart of the above, folders will sub-folders and tf files which contains terraform resource or module definitions and files for the Infrastructure
* On the Base folder , we have common.tfvars and terraform.tfvars which contains values to all variables and terraform.tfvars containing the Terragrunt definition

# How this Vault Infrastructure is structured

The code for Vault Infrastructure is divided into three functions
1. Basic AWS Infrastructure
2. Consul Backend
3. Vault Cluster

The terragrunt dependencies are created in the same order as defined above


# How to Run this code

## Initial One Time Setup
Since we are using External CA for the certificates used for Vault and Conusl, these needs to be done in stages. These needs to be done only for the first time. Post that we can use `plan-all` or `apply-all` for planning and creating the setup

1. Go to basic_infra folder and run `terragrunt plan` to plan the infrastructure and `terragrunt apply` to apply the infrastructure.
2. Then go to consul and execute `terragrunt  plan/apply --target` on all the key and csr modules
3. Then go to vault and execute `terragrunt  plan/apply --target` on all the key and csr modules
4. Get the CSRs from the output variables of the respective folders and get it signed from the CA
5. Once done, copy the signed certificates under certs folder of Vault and Consul respectively as given

Post the above, run `terragrunt plan-all or apply-all` from the root folder to create rest of the Infrastructure

## Switching Over from Blue to Green or vice versa
This example assumes that we do have a blue setup running and we wanted to setup and Switch to Green

1. First set the Green , by running `terragrunt plan-all/apply-all -var is_blue_mode_active="yes" -var is_green_mode_active="yes" -var keep_dns_deployment_mode="blue"``
2. Post the verification of Green Setup, to Switch over, run
`terragrunt plan-all/apply-all -var is_blue_mode_active="no" -var is_green_mode_active="yes" -var keep_dns_deployment_mode="green"`


# AMI
We use our custom encrypted AMI which has all the necessary installations like Consul, Vault, etc and necessary firewall rules integrated into it. For more details on how to build the AMI, refer to our GIT repo https://github.com/dwp/packer-infrastructure

# Overview of Setup done by Terraform

Because of the Terragrunt dependency definition , we create the necessary AWS infrastructure like VPC, Gateways, etc and then build Consul Servers with Initial Setup and then move on to create Vault Clusters.

## basic_infra
This section of Terraform Code creates 3 basic requirements for the Base Infrastructure to support Vault and Consul Nodes.

* [AWS Basic Infrastructure](#AWSBasicInfrastructure)
* [KMS Key](#KMSKeyCreation) for Encrypting Vault Management Tokens and ACL Tokens generated during Consul Initial setup
* [Upload Slack Hook](#Slack) information for sending alerts when Backup of Consul Failed

### AWS Basic Infrastructure<a name="AWSBasicInfrastructure"></a>
* A VPC with dhcp options
* One Public Subnet and 2 Private Subnets named consul and vault
* One Internet Gateway for the project/region and NAT Gateways for each Availability Zone (based on `what_services_i_need` variable)
* One Generic Security Group to attach to Consul and Vault Nodes , with outbound to Amazon IPs of the region on 443
* SSH Key Pair creation and uploading to AWS (based on `what_services_i_need` variable)
* VPC Peer to Monitoring (Prometheus) (based on `what_connections_i_need` variable)
* VPC Peer to VPN VPC (based on `what_connections_i_need` variable)
* Adds the necessary rules for inbound/outbound of Monitoring and VPN access (based on `subnet_names_on_route_to_peer` variable)
* Adds the Inbound SSH access to the Generic Security Group. (if `what_services_i_need` variable contains ssh)
* Attaches the VPC to existing Private Route53 Zone (based on `associate_private_zones` variable)

### KMS Key Creation<a name="KMSKeyCreation"></a>
* Creates a KMS Key for Encrypting Vault Management Tokens and ACL Tokens created by Consul during initial setup

### Slack<a name="Slack"></a>
* Uploads Slack Hook URLs and Slack Channel information to SSM for Lambda to pick up and notify any problems with Consul Backup

## consul
This section of Terraform code creates all the necessary Consul Configuration, this is done through the combination of Terraform and EC2 User data scripts, the setup done includes, creating certificates, configuring Consul Server configuration , do LVM operations, create and apply Consul ACL policies, Create ACL tokens , backup and restore from backup (if required). It also sets the Mutual TLS between Consul Server and Consul Client.

## vault
This section of Terraform code creates all the necessary Vault Configuration, this is done through the combination of Terraform and EC2 User data scripts, the setup done includes, creating certificates, configuring Vault Server configuration , do LVM operations, apply Standard Vault ACL policies, Configure LDAP Groups and map LDAP groups with policies, rotate Unseal Keys and destroy root token


## Setup Diagram
The terraform sets up the infrastructure as below and ready for use
![Vault Setup](./github-diagram.jpg)

# Future Plans
Planning to convert this into a Terraform child module which does all of these things with only variable changes

> Note: Replace any values starting with '<' and ending '>' in all the files with appropriate values before running terraform
