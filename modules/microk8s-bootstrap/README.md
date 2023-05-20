# microk8s-bootstrap Terraform Module

This module will be triggered as part of [rpi-microk8s-bootstrap project](../../) and its use-cases are [described as part of project README](../../#how-can-this-terraform-project-help-me).

Based on some of its [input variable values](../../main.tf), [microk8s-bootstrap.tpl](./microk8s_bootstrap.tpl) will be rendered producing "microk8s_bootstrap.py", this and "~/.ssh/id_rsa.pub" file (if present on local system) will be copied to target RPI node after SSH connection has been made by Terraform, followed by running "microk8s_bootstrap.py" on target RPI node.

By design, this module will invalidate state for `null_resource`, and "microk8s_bootstrap.py" will run every time Terraform code is executed. As mentioned in [rpi-microk8s-bootstrap README](../../README.md#please-note), it is designed to be run numerous times without overwriting existing configurations.

## Purpose of [microk8s-bootstrap.tpl](./microk8s_bootstrap.tpl) file

[Once rendered as microk8s_bootstrap.py file](../../#to-only-create-microk8s_boostrappy-file-from-microk8s-bootstraptpl-run), main functionality will be to automatically perform manual steps mentioned as part of:

* "Step 3: Installing and configuring Ubuntu server on RPI 4’s nodes" and
* "Step 4: Installing and configuring MicroK8s" 

sections of [wp-k8s: WordPress on privately hosted Kubernetes cluster (Raspberry Pi 4 + Synology)](https://foolcontrol.org/?p=4004) blog post. Also related: [wp-k8s: WordPress on Kubernetes project](https://github.com/AdnanHodzic/wp-k8s).

### Functionality:

* Step 3.2: Configure SSH key based auth
* Step 3.3 Configure hostname (static)
* Configuring timezone & ntp
* Configure non interactive (automatic service restart)
* Perform full system upgrade
* Step 3.4  Get latest updates & 3.5 Install packages necessary for NFS mount
* Step 3.6: Configure boot configuration for use of `cgroup` memory
* Step 3.8: Disable cloud-init network capabilities
* Step 3.10 Comment existing 50-cloud-init.yaml contents and add static network configuration
* Step 4.1: install microk8s
* Enabling microk8s metallb addon
* Enable microk8s ingress, dns, dashboard addons
* Install linux-modules-extra-raspi
* Step 4.2: Eliminate need to run "sudo microk8s" by adding ubuntu user to microk8s group
* Step 3.11: Print message to add IP of each RPI node to/etc/hosts

<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_local"></a> [local](#provider\_local) | n/a |
| <a name="provider_null"></a> [null](#provider\_null) | n/a |
| <a name="provider_template"></a> [template](#provider\_template) | n/a |

## Resources

| Name | Type |
|------|------|
| [local_file.save-rendered-bootstrapfile](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [null_resource.microk8s-bootstrap](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.this](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [template_file.bootstrap](https://registry.terraform.io/providers/hashicorp/template/latest/docs/data-sources/file) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_bootstrapfile"></a> [bootstrapfile](#input\_bootstrapfile) | n/a | `string` | `"microk8s_bootstrap.py"` | no |
| <a name="input_current_ip"></a> [current\_ip](#input\_current\_ip) | n/a | `string` | `"192.168.1.49"` | no |
| <a name="input_metallb_pool_range"></a> [metallb\_pool\_range](#input\_metallb\_pool\_range) | n/a | `string` | `"192.168.1.110-192.168.1.120"` | no |
| <a name="input_microk8s_version"></a> [microk8s\_version](#input\_microk8s\_version) | n/a | `string` | `"1.24"` | no |
| <a name="input_net_interface"></a> [net\_interface](#input\_net\_interface) | n/a | `string` | `"eth0"` | no |
| <a name="input_new_hostname"></a> [new\_hostname](#input\_new\_hostname) | n/a | `string` | `"rpi-a"` | no |
| <a name="input_new_rpi_ip"></a> [new\_rpi\_ip](#input\_new\_rpi\_ip) | n/a | `string` | `"192.168.1.100"` | no |
| <a name="input_password"></a> [password](#input\_password) | n/a | `string` | `"ubuntu"` | no |
| <a name="input_rpi_dns"></a> [rpi\_dns](#input\_rpi\_dns) | n/a | `string` | `"192.168.1.1"` | no |
| <a name="input_rpi_gateway"></a> [rpi\_gateway](#input\_rpi\_gateway) | n/a | `string` | `"192.168.1.1"` | no |
| <a name="input_ssh_pub_file"></a> [ssh\_pub\_file](#input\_ssh\_pub\_file) | n/a | `string` | `"/.ssh/id_rsa.pub"` | no |
| <a name="input_timezone"></a> [timezone](#input\_timezone) | n/a | `string` | `"Europe/Amsterdam"` | no |
| <a name="input_username"></a> [username](#input\_username) | n/a | `string` | `"ubuntu"` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->