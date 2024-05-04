#!/bin/bash
yum install httpd -y 
systemctl start httpd 
sysremctl enable httpd