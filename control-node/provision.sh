#!/bin/sh

yum -y install epel-release
yum -y install ansible
ansible-galaxy install geerlingguy.mysql
cat <<EOT >> /etc/hosts
192.168.56.2 control-node
192.168.56.3 app
192.168.56.4 db
EOT

