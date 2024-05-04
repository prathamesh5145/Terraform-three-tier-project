#!b/in/bash
dnf install mariadb105-server -y
systemctl start mariadb
systemctl enable mariadb