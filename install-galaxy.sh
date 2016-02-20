#!/bin/bash

GALAXY_VERSION=15.10.1

# Install vim
apt-get update
apt-get install -y vim wget python

# Install Galaxy 
wget https://github.com/galaxyproject/galaxy/archive/v$GALAXY_VERSION.tar.gz
tar -xzvf v$GALAXY_VERSION.tar.gz
rm v$GALAXY_VERSION.tar.gz
mv galaxy-$GALAXY_VERSION galaxy

sed 's/^#host = 127.0.0.1/host = 0.0.0.0/' /root/galaxy/config/galaxy.ini.sample > /root/galaxy/config/galaxy.ini
sed -i "s@^#file_path = database/files@file_path = /opt/workdir/galaxy_files@" /root/galaxy/config/galaxy.ini
