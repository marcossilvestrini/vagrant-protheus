#!/bin/bash

# SSH,FIREWALLD AND SELINUX
cat /security/id_rsa.pub >>.ssh/authorized_keys
sudo systemctl stop firewalld
sudo systemctl disable firewalld
sudo setenforce Permissive

# PACKAGES FOR PROVISION
dnf install python3 -y
