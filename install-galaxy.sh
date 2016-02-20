#!/bin/bash

# Install vim
apt-get update
apt-get install -y vim wget python

# Install Galaxy 15.07
wget https://github.com/galaxyproject/galaxy/archive/v15.07.tar.gz
tar -xzvf v15.07.tar.gz
rm v15.07.tar.gz
mv galaxy-15.07 galaxy

sed 's/^#host = 127.0.0.1/host = 0.0.0.0/' /root/galaxy/config/galaxy.ini.sample > /root/galaxy/config/galaxy.ini
sed -i "s@^#file_path = database/files@file_path = /opt/workdir/galaxy_files@" /root/galaxy/config/galaxy.ini
