#!bin/bash
sudo rpm -i https://ftp.postgresql.org/pub/pgadmin/pgadmin4/yum/pgadmin4-redhat-repo-1-1.noarch.rpm
sudo dnf install pgadmin4-web
dnf install policycoreutils-python-utils
sudo /usr/pgadmin4/bin/setup-web.sh
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --reload

#access: http://127.0.0.1/pgadmin4