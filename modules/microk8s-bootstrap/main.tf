# microk8s_bootstrap.tpl template file variables
data "template_file" "bootstrap" {
  template = "${file("${path.module}/microk8s_bootstrap.tpl")}"
  # All variables that will be used as part of output file
  # microk8s_bootstrap.py must be defined here to be picked up ...
  vars = {
    user = "${var.username}"
    password = "${var.password}"
    timezone = "${var.timezone}"
    hostname = "${var.new_hostname}"
    interface = "${var.net_interface}"
    ip = "${var.new_rpi_ip}"
    gateway = "${var.rpi_gateway}"
    dns = "${var.rpi_dns}"
    microk8s_version = "${var.microk8s_version}"
    metallb_pool_range = "${var.metallb_pool_range}"
    current_ip = "${var.current_ip}"
    new_rpi_ip = "${var.new_rpi_ip}"
  }
}

# Render template file microk8s_bootstrap.tpl to microk8s_bootstrap.py
resource "local_file" "save-rendered-bootstrapfile" {
  content = "${data.template_file.bootstrap.rendered}"
  filename = "${path.root}/${path.module}/${var.bootstrapfile}"
}

# Trigger when template is rendered
resource "null_resource" "this" {
  triggers = {
    "bootstrapfile" = "${data.template_file.bootstrap.rendered}"
  }
}

# SSH to the target RPI node and perform necessary actions
resource "null_resource" "microk8s-bootstrap" {
  connection {
    type = "ssh"
    user = "${var.username}"
    password = "${var.password}"
    host = "${var.current_ip}"
  }

# Copy localy SSH id_rsa.pub file to target RPI node
  provisioner "file" {
    source = "~/.ssh/id_rsa.pub"
    destination = "/home/${var.username}/id_rsa.pub"
  }
  
  # Copy locally generated microk8s_bootstrap.py to target RPI node
  provisioner "file" {
    source  = "${path.root}/modules/microk8s-bootstrap/${var.bootstrapfile}"
    destination = "/home/${var.username}/${var.bootstrapfile}"
  }

  # Invalidate state for `null_resource`, so microk8s_bootstrap.py will
  # always be run as part of `remote-exec` using timestamp
  triggers = {
    always_run = "${timestamp()}"
  }

  # Execute generated bootstrap.py on target RPI node
  provisioner "remote-exec" {
    inline = [
      "echo ${var.password} | sudo -S python3 /home/${var.username}/${var.bootstrapfile}"
    ]
  }
}