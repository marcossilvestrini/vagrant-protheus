#!/bin/bash

echo 'Install Dependences'
sudo yum install libXrandr -y
sudo yum install libXcursor -y
sudo yum install libXinerama -y
sudo yum install libXft -y

echo 'Search Postgresql-odbc in Repo'
sudo yum search postgre | grep odbc

echo 'Install Postgresql-odbc'
sudo yum install unixODBC unixODBC-devel
sudo yum install postgresql-odbc.x86_64 -y

# odbcinst -j

# simbolik link for dbaccess
sudo ln -sf /usr/lib64/psqlodbc.so /usr/lib64/libpsqlodbc.so
# clientlibrary=/opt/unixODBC/lib/libodbc.so