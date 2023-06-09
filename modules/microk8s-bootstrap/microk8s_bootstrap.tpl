#!/usr/bin/env python3
#
# File generated by rpi-microk8s-bootstrap Terraform project:
# https://github.com/AdnanHodzic/rpi-microk8s-bootstrap
# by rendering contents of microk8s_bootstrap.tpl file

# Author: Adnan Hodzic <adnan@hodzic.org>
# Blog post: https://foolcontrol.org/?p=4555

import os
import subprocess
import socket
import fileinput
import re

# func to return if file/dir exists
def check_loc(file_path):
    try:
        if os.path.exists(file_path):
            return True
        else:
            return False
    except Exception as e:
        return False, print(f"An error occurred: {e}")
    
# check if contents of the files are the same, return true if contents 1st file are part of 2nd file
def file_contains_other_file(file_path_1, file_path_2):
    with open(file_path_1, 'r') as f1:
        with open(file_path_2, 'r') as f2:
            file1_contents = f1.read()
            file2_contents = f2.read()
            return file1_contents in file2_contents

# find a line, string or a pattern in a file
def find_pattern(file_path, pattern):
    try:
        with open(file_path, "r") as f:
            file_content = f.read()
        match = re.search(pattern, file_content)
        if match:
            return True
            #return True, print(f"Pattern: \"{pattern}\" found")
        else:
            return False

    except Exception as e:
         return False, print(f"An error has occured: {e}")

# Step 3.2: Configure SSH key based auth
auth_keys = "/home/${user}/.ssh/authorized_keys"
id_rsa_content = "/home/${user}/id_rsa.pub"

print("\n--- Configure SSH key based auth ---\n")
if check_loc(auth_keys) == True:
    if check_loc(id_rsa_content):
        # check if auth_keys don't contain id_rsa_content
        if not file_contains_other_file(id_rsa_content, auth_keys):
            with open(id_rsa_content, "r") as src_file, open(auth_keys, "a") as dest_file:
                dest_file.write(src_file.read())
    else:
        print(f"Error: {id_rsa_content} not found!")
    print("SSH key based auth already configured.")

elif check_loc(auth_keys) == False:
    home_dir = "/home/${user}/"
    os.makedirs(home_dir + ".ssh/" , exist_ok=True)
    subprocess.run(["chmod", "700", home_dir])
    with open(home_dir + ".ssh/authorized_keys", "w"):
        pass
    subprocess.run(["chmod", "600", home_dir + ".ssh/authorized_keys"])
    subprocess.run(["chown", "${user}:${user}", home_dir + ".ssh/authorized_keys"])
    # check if auth_keys don't contain id_rsa_content
    if check_loc(id_rsa_content):
        if not file_contains_other_file(id_rsa_content, auth_keys):
            with open(id_rsa_content, "r") as src_file, open(auth_keys, "a") as dest_file:
                dest_file.write(src_file.read())
    else:
        print(f"Error: {id_rsa_content} not found!")
    print("Action completed successfully.")
else:
    print("SSH key based auth already configured.")

# configure sudo without password for ubuntu user
print("\n--- Configure sudo without password for ${user} ---\n")

sudoers_file = "/etc/sudoers"
nopasswd_append = "ubuntu ALL=(ALL:ALL) NOPASSWD:ALL"

with open(sudoers_file, "r") as f:
    lines = f.readlines()

    if find_pattern(sudoers_file, "NOPASSWD") == False:
      with open(sudoers_file, "a") as f:
          f.write("\n" + nopasswd_append + "\n")

print("Action completed successfully.\n")

# Step 3.3 Configure hostname
print("\n--- Configure hostname ---\n")
hostname = "${hostname}"
subprocess.run(["hostnamectl", "set-hostname", "${hostname}"])
print(f"Hostname set to: {socket.gethostname()}")

# Configuring timezone & ntp
print("\n--- Configure timezone & ntp  ---\n")
subprocess.run(["sudo", "timedatectl", "set-timezone", "${timezone}"])
subprocess.run(["sudo", "timedatectl", "set-ntp", "true"])
print("Action completed successfully.\n")
subprocess.run(["timedatectl"])

# Configure non interactive (automatic service restart)
print("\n--- Configure non interactive (automatic service restart) ---\n")
subprocess.run(["sudo", "export", "NEEDRESTART_MODE=a"])
subprocess.run(["sudo", "export", "DEBIAN_FRONTEND=noninteractive"])
subprocess.run(["sudo", "sed", "-i", "s/#\$nrconf{kernelhints} = -1;/\$nrconf{kernelhints} = -1;/g", "/etc/needrestart/needrestart.conf"])

# Step 3.4  Get latest updates & 3.5 Install packages necessary for NFS mount
print("\n--- Install system updates & necessary packages ---\n")
subprocess.run(["sudo", "apt", "update"])
subprocess.run(["sudo", "NEEDRESTART_MODE=a", "apt", "upgrade", "-y"])
subprocess.run(["sudo", "NEEDRESTART_MODE=a", "apt", "install", "nfs-common", "-y"])
print("\nAction completed successfully.")

# Step 3.6: Configure boot configuration for use of `cgroup` memory
# Without configuring this, Kubernetes setting will never get to “Ready” state!
print("\n--- Configure boot configuration for use of `cgroup` memory ---")

cmdline_file = "/boot/firmware/cmdline.txt"
cgroup_append = "cgroup_enable=cpuset cgroup_enable=memory cgroup_memory=1 "

if find_pattern("/boot/firmware/cmdline.txt", "cgroup_enable=cpuset cgroup_enable=memory cgroup_memory=1") == False:

    for line in fileinput.input(cmdline_file, inplace=True):
        if fileinput.isfirstline():
            print(cgroup_append + line, end='')
        else:
            print(line, end='')

print("\nAction completed successfully.")

# Step 3.8: Disable cloud-init network capabilities
print("\n--- Disable cloud-init network capabilities ---\n")

network_config_file = "/etc/cloud/cloud.cfg.d/99-disable-network-config.cfg"
append_disable_netconf = "network: {config: disabled}\n"

try:
  with open(network_config_file, "w") as f:
      f.write(append_disable_netconf)
  print(f"Successfully added \"{append_disable_netconf.strip()}\" to:\n{network_config_file}")
except Exception as e:
    print(f"\nAn error occurred: {e}")

# Step 3.10 pt1: Comment existing contents and add static configuration
print("\n--- Disable current & append static network config ---\n")

cloud_init="/etc/netplan/50-cloud-init.yaml"

network_config = """
network:
  ethernets:
    ${interface}:
      addresses: [${ip}/24]
      gateway4: ${gateway}
      nameservers:
        addresses: [${dns}]
  version: 2
"""

if find_pattern(cloud_init, "${ip}/24") == False:
  for line in fileinput.input(cloud_init, inplace=True):
    if line.strip() and not line.startswith("#"):
        line = "# " + line
    print(line, end='')

  with open(cloud_init, "a") as f:
      f.write(network_config)

print(f"\nFollowing content successfully added to: {cloud_init}")
with open(cloud_init, "r") as f:
    print("\n" + f.read())

# Step 4.1: install microk8s
print(f"\n--- Installing microk8s v${microk8s_version} ---\n")
subprocess.run(["sudo", "snap", "install", "microk8s", "--channel=${microk8s_version}/stable", "--classic"])

# Enable microk8s ingress, dns, dashboard addons
# ToDo: make a loop out of this
print(f"\n--- Enabling necessary microk8s addons ---\n")
subprocess.run(["sudo", "microk8s", "enable", "ingress"])
print("")
subprocess.run(["sudo", "microk8s", "enable", "dns"])
print("")
subprocess.run(["sudo", "microk8s", "enable", "dashboard"])

# Enable microk8s metallb addon
print(f"\n--- Enabling microk8s metallb addon ---\n")
subprocess.run(["sudo", "microk8s", "enable", "metallb:${metallb_pool_range}"])

# Install linux-modules-extra-raspi
print(f"\n--- Installing linux-modules-extra-raspi ---\n")
subprocess.run(["sudo", "apt", "update"])
subprocess.run(["sudo", "NEEDRESTART_MODE=a", "apt", "install", "linux-modules-extra-raspi", "-y"])

# Step 4.2: Eliminate need to run "sudo microk8s" by adding ubuntu user to microk8s group
print(f"\n--- Add ability to run microk8s without prepending `sudo` ---\n")
subprocess.run(["sudo", "usermod", "-a", "-G", "microk8s", "${user}"])
subprocess.run(["sudo", "chown", "-f", "-R", "${user}", "/home/${user}/.kube"])

# Step 3.11: Print message to add IP of each RPI node to/etc/hosts
# entry is added each time bootstrap is run
print("--- Add RPI node IP/hostname to /etc/cloud/templates/hosts.debian.tmpl file ---")

hosts_file = "/etc/cloud/templates/hosts.debian.tmpl"
entry = "${ip} ${hostname}"

with open(hosts_file, "r") as f:
    lines = f.readlines()

    if find_pattern(hosts_file, entry) == False:
      with open(hosts_file, "a") as f:
          f.write("\n" + entry + "\n")

print("\n--- Setup complete ---\n")
print("""Please note: as you add new nodes to the Kubernetes cluster make 
sure to add each node IP/hostname to /etc/cloud/templates/hosts.debian.tmpl 
file for each node to know about others node location on the nework.

Example contents of each nodes /etc/hosts for 3 node K8s cluster:
192.168.1.100 rpi-a
192.168.1.101 rpi-b
192.168.1.102 rpi-c

These changes should be made to ${current_ip} node.

Restart RPI node to apply changes, i.e: sudo reboot
after which RPI node will be available on: ${ip}\n
""")