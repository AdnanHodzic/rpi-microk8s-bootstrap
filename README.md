

# rpi-microk8s-bootstrap

This repo contains ["microk8s-bootstrap" Terraform module](./modules/microk8s-bootstrap) used for automated provisioning of Ubuntu server & MicroK8s on a Raspberry Pi (RPI) node. In matter of minutes, final result will be a node which is ready to start new Kubernetes cluster, or join an existing one. Ready to have Kubernetes workloads deployed to it.

It's designed to automatically perform manual steps described as part of:

* "Step 3: Installing and configuring Ubuntu server on RPI 4’s nodes" and
* "Step 4: Installing and configuring MicroK8s" 

sections of [wp-k8s: WordPress on privately hosted Kubernetes cluster (Raspberry Pi 4 + Synology)](https://foolcontrol.org/?p=4004) blog post. Also related: [wp-k8s: WordPress on Kubernetes project](https://github.com/AdnanHodzic/wp-k8s).

## How can this Terraform project help me?

Project was created and designed with 2 main use-cases in mind:

### 1. Bootstrap Ubuntu server & MicroK8s to a RPI device, automatically and in matter of minutes

As mentioned above, installing and configuring Ubuntu server & MicroK8s to be ready to start new Kubernetes cluster, or join an existing one, consists of many manual steps and is a lengthy process.

By setting few variable values and running terraform code as explained in section below, this terraform project allows you to seamlessly have Ubuntu server with MicroK8s configured with all necessary changes to deploy Kubernetes workloads on it. Ultimately, turning your RPI device into a Kubernetes cluster or one of its nodes in matter of minutes.

Result of successful Terraform code run:

<img src="http://foolcontrol.org/wp-content/uploads/2023/05/rpi-microk8s-bootstrap-terraform-apply.png" width="640" alt="Example rpi-microk8s-bootstrap Terraform project run"/>

For full list of changes that will be made, please refer to ["microk8s-bootstrap" Terraform module README](./modules/microk8s-bootstrap).

### 2. Upgrade to a new Kubernetes (MicroK8s) release and/or perform Ubuntu upgrade on an existing RPI node of your Kubernetes cluster

Without this project, upgrading to a new Kubernetes (MicroK8s) version is a daunting (manual) task which involves:

* Getting a list of nodes of your K8s cluster
* Draining worker nodes
* Verifying no workloads are running on target node
* Upgrading Kubernetes (MicroK8s) on target node
* Verifying upgrade went well and then resume pod scheduling on the upgraded node

By utilizing this project, same process is as simple as taking the target node ouf of the cluster and specifying desired version of Kubernetes (MicroK8s) in [variables](https://github.com/AdnanHodzic/rpi-microk8s-bootstrap/blob/5a3f1f1ab1a483c885137d4ff5a243a9cea7bb3a/main.tf#L33). After Terraform code execution, node can be added back to the cluster and all software updates for Ubuntu will also be installed. If same `microk8s_version` variable value was used as before (during provisioning), terraform code execution will only consist of updating all software on selected node.

## How to use this project?

### Pre-requisites
* RPI >= 4 device
* Installed Ubuntu server image to SD card (explained as part of [Step 3.1: Write Ubuntu server >= 20.04.x arm64 image to RPI’s](https://foolcontrol.org/?p=4004) section)
* Run `terraform init`


Verified and tested on Raspberry Pi 4 Model B & Ubuntu 22.04.

#### Please note! 

As part of ["microk8s-bootstrap" module](./modules/microk8s-bootstrap) execution, [microk8s-bootstrap.tpl](./modules/microk8s-bootstrap/microk8s_bootstrap.tpl) file will generate "rpi-microk8s-boostrap.py" file during Terraform code execution that has all necessary changes, which is designed to be run numerous times without overwriting existing configurations. Meaning, this code will run *every time* and as such won't need to rely on functionality of Terraform state file. Hence, undocumented terraform ["inmem" backend](https://github.com/AdnanHodzic/rpi-microk8s-bootstrap/blob/5a3f1f1ab1a483c885137d4ff5a243a9cea7bb3a/main.tf#L3) is used, which will execute terraform code without generating terraform.tfstate file. To override this behavior, comment/remove its code block.

### How to bootstrap Ubuntu server & MicroK8s to a new RPI device, ready to deploy Kubernetes workloads

After Ubuntu image was written to SD card as described as part of [pre-requisites](#pre-requisites), make sure to refer to [rpi-microk8s-bootstrap/main.tf](./main.tf) file and update all variables accordingly!

In particular: 

  * password
  * new_hostname
  * current_ip
  * new_rpi_ip
  * microk8s_version

In case of writing to more then one node, simply update above mentioned variables and subsequently run the same Terraform code on next RPI node, i.e:

```
terraform plan
terraform apply
```

Followed by running changes explained as part of [Step 4.9: Enable High Availability k8s cluster by adding rest of RPI nodes](https://foolcontrol.org/?p=4004) section.

For more information, please refer to [rpi-microk8s-bootstrap/main.tf](./main.tf) or ["microk8s-bootstrap" module README](./modules/microk8s-bootstrap) file. After successful Terraform code execution, please refer to:

* "Step 4.4: Check cluster status" and
* "Step 4.6: Configure access to microk8s cluster by configuring kubeconfig"

sections of [wp-k8s: WordPress on privately hosted Kubernetes cluster (Raspberry Pi 4 + Synology)](https://foolcontrol.org/?p=4004) blog post to complete the node access configuration.  

### How to Upgrade to a new Kubernetes (MicroK8s) or Ubuntu release on an existing RPI node of your Kubernetes cluster

In case of high availability setup, where for example you had RPI K8s cluster consisting of 3 nodes i.e: rpi-a, rpi-b, rpi-c which were running on Ubuntu server 20.04 and Kubernetes (Microk8s) 1.24 release. 

```
kubectl get nodes -o wide
NAME    STATUS   ROLES    AGE   VERSION   INTERNAL-IP     EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION      CONTAINER-RUNTIME
rpi-c   Ready    <none>   61d   v1.24.0   192.168.1.102   <none>        Ubuntu 20.04.5 LTS   5.10.0-1022-raspi   containerd://1.5.9
rpi-a   Ready    <none>   63d   v1.24.0   192.168.1.100   <none>        Ubuntu 20.04.5 LTS   5.10.0-1022-raspi   containerd://1.5.9
rpi-b   Ready    <none>   59d   v1.24.0   192.168.1.101   <none>        Ubuntu 20.04.5 LTS   5.10.0-1022-raspi   containerd://1.5.9
```

You want to identify what's the cluster leader (master) node, by SSH-ing to one of the nodes and running following command, i.e:
``` 
ubuntu@rpi-a:~$ sudo -E /snap/microk8s/current/bin/dqlite -c /var/snap/microk8s/current/var/kubernetes/backend/cluster.crt -k /var/snap/microk8s/current/var/kubernetes/backend/cluster.key -s file:///var/snap/microk8s/current/var/kubernetes/backend/cluster.yaml k8s ".leader"
192.168.1.102:19001
```

In this case, our leader node is 192.168.1.102 (rpi-c) and to have minimum downtime on your Kubernetes cluster workloads, it would be the best idea to take this node out of the cluster last and start by taking one of the workers node out of the cluster first, i.e: rpi-a
 
Remove the node from cluster by running following command on departing node: 
```
ubuntu@rpi-a:~$ microk8s leave
Generating new cluster certificates.
Waiting for node to start. . 
``` 
 
Verify status on MicroK8s leader node:
```
ubuntu@rpi-c:~$ microk8s kubectl get nodes -o wide
NAME    STATUS     ROLES    AGE   VERSION   INTERNAL-IP     EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION      CONTAINER-RUNTIME
rpi-c   Ready      <none>   61d   v1.24.0   192.168.1.102   <none>        Ubuntu 20.04.5 LTS   5.10.0-1022-raspi   containerd://1.5.9
rpi-b   Ready      <none>   63d   v1.24.0   192.168.1.101   <none>        Ubuntu 20.04.5 LTS   5.10.0-1022-raspi   containerd://1.5.9
rpi-a   NotReady   <none>   59d   v1.24.0   192.168.1.100   <none>        Ubuntu 20.04.5 LTS   5.10.0-1022-raspi   containerd://1.5.9
```

Remove microk8s worker node from leader node:
```
ubuntu@rpi-c:~$ sudo microk8s remove-node rpi-a
ubuntu@rpi-c:~$ microk8s kubectl get nodes -o wide
NAME    STATUS   ROLES    AGE   VERSION   INTERNAL-IP     EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION      CONTAINER-RUNTIME
rpi-c   Ready      <none>   61d   v1.24.0   192.168.1.102   <none>        Ubuntu 20.04.5 LTS   5.10.0-1022-raspi   containerd://1.5.9
rpi-b   Ready      <none>   63d   v1.24.0   192.168.1.101   <none>        Ubuntu 20.04.5 LTS   5.10.0-1022-raspi   containerd://1.5.9
```

In case node can't be removed for some reason, you can always resort to removing it by force:  `sudo microk8s remove-node -f rpi-a`

After Ubuntu image was written to SD card (make sure to use new Ubuntu release!) for this node as described of [pre-requisites](#pre-requisites) make sure to refer to [rpi-microk8s-bootstrap/main.tf](./main.tf) file and update all variables accordingly!

In particular: 

  * password
  * new_hostname
  * current_ip
  * new_rpi_ip
  * microk8s_version

Please note, 

1. ["microk8s-bootstrap" module](./modules/microk8s-bootstrap) will setup SSH key based authentication if SSH key was found on local system, hence if this was done value provided in `password` variable won't have any effect now since authentication will be based on SSH key. 
2. `microk8s_version` variable value must be updated with desired Kubernetes (microk8s) release upgrade version.
3. Also, for this use-case `current_ip` and `new_rpi_ip` variable values *should remain the same*. 

In case of writing to more then one node, simply update above mentioned variables and subsequently run the same Terraform code on next RPI node, i.e:

```
terraform plan
terraform apply
```

For more information, please refer to [rpi-microk8s-bootstrap/main.tf](./main.tf) or ["microk8s-bootstrap" module README](./modules/microk8s-bootstrap) file. After successful Terraform code execution, please refer to:

* "Step 4.4: Check cluster status" and
* "Step 4.6: Configure access to microk8s cluster by configuring kubeconfig"

sections of [wp-k8s: WordPress on privately hosted Kubernetes cluster (Raspberry Pi 4 + Synology)](https://foolcontrol.org/?p=4004) blog post to complete the node access configuration.  

To add new & updated node as part of the existing cluster, on MicroK8s leader node run: 
```
ubuntu@rpi-c:~$ microk8s add-node
From the node you wish to join to this cluster, run the following:
microk8s join 192.168.1.102:25000/a2b2219af978086966ff6fe2467711a1/18a446d13x81

Use the '--worker' flag to join a node as a worker not running the control plane, eg:
microk8s join 192.168.1.102:25000/a2b2219af978086966ff6fe2467711a1/18a446d13x81 --worker

If the node you are adding is not reachable through the default interface you can use one of the following:
microk8s join 192.168.1.102:25000/a2b2219af978086966ff6fe2467711a1/18a446d13x81
```

Followed by running as instructed on node that's supposed to join the target, i.e:
```
ubuntu@rpi-a:~$ microk8s join 192.168.1.102:25000/a2b2219af978086966ff6fe2467711a1/18a446d13x81
WARNING: Hostpath storage is enabled and is not suitable for multi node clusters.

Contacting cluster at 192.168.1.102
Waiting for this node to finish joining the cluster. .. .. .. ..  
ubuntu@rpi-a:~$ microk8s kubectl get nodes -o wide
NAME    STATUS   ROLES    AGE   VERSION   INTERNAL-IP     EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION      CONTAINER-RUNTIME
rpi-b   Ready    <none>   61d   v1.24.0   192.168.1.101   <none>        Ubuntu 20.04.5 LTS   5.10.0-1022-raspi   containerd://1.5.9
rpi-c   Ready    <none>   63d   v1.24.0   192.168.1.102   <none>        Ubuntu 20.04.5 LTS   5.10.0-1022-raspi   containerd://1.5.9
rpi-a   Ready    <none>   25s   v1.27.1   192.168.1.100   <none>        Ubuntu 22.04.2 LTS   5.15.0-1027-raspi   containerd://1.6.15
```

Kubernetes can run existing Kubernetes workloads on nodes consisting of different Kubernetes (MicroK8s) & Ubuntu releases, which will allow your cluster to run in uninterrupted state, as portrayed in code block above.

### To only create "microk8s_boostrap.py" file from [microk8s-bootstrap.tpl](./modules/microk8s-bootstrap/microk8s_bootstrap.tpl) run:

```
terraform plan -target=module.microk8s-bootstrap.local_file.save-rendered-bootstrapfile
terraform apply -target=module.microk8s-bootstrap.local_file.save-rendered-bootstrapfile
```

### Discussion: 

* Blog post: [rpi-microk8s-bootstrap: Automate RPI device conversion into Kubernetes cluster nodes with Terraform](https://foolcontrol.org/?p=4555)
