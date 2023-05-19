variable "current_ip" {
  default = "192.168.1.49"
}

variable "new_rpi_ip" {
  default = "192.168.1.100"
}
variable "rpi_gateway" {
  default = "192.168.1.1"
}

variable "rpi_dns" {
  default = "192.168.1.1"
}

variable "metallb_pool_range" {
  default = "192.168.1.110-192.168.1.120"
}

variable "username" {
  default = "ubuntu"
}
variable "password" {
  default = "ubuntu"
}

variable "new_hostname" {
  default = "rpi-a"
}

variable "microk8s_version" {
  default = "1.27"
}

variable "timezone" {
  default = "Europe/Amsterdam"
}

variable "net_interface" {
  default = "eth0"
}

variable "ssh_pub_file" {
  default = "/.ssh/id_rsa.pub"
}

variable "bootstrapfile" {
  default = "microk8s_bootstrap.py"
}

