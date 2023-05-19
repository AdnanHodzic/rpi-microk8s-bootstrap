# do not generate terrafom.tfstate file, refer to README for more details
terraform {
  backend "inmem" {}
}

module "microk8s-bootstrap" {
  source = "./modules/microk8s-bootstrap"

  # Values specified here will override default variables defined in:
  # ./modules/microk8s-bootstrap/variables.tf

  # Username used to SSH to target RPI node
  #username = "ubuntu"

  # Password used to SSH to target RPI node
  # If "~/.ssh/id_rsa.pub" is present, SSH based authentication will
  # be enabled, so password won't be needed when SSH-ing to node
  password = "change-M3"

  # New desired hostname to be used for target RPI node IP
  new_hostname = "rpi-a"

  # Update if any interface other then "eth0" is used 
  #net_interface = "eth0"

  # Current RPI node IP, can be found by i.e: "ping rpi-a.local"
  current_ip = "192.168.1.49"

  # New desired target RPI node static IP
  new_rpi_ip = "192.168.1.100"

  # microk8s (kubernetes) version to be installed
  microk8s_version = "1.27"

  # Add own values if metallb & different pool range is to be used
  # metallb_pool_range = "192.168.1.110-192.168.1.120"
}