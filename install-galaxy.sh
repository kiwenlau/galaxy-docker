#!/bin/bash

# Install vim
apt-get update
apt-get install -y vim wget python

# Install Galaxy 15.07
wget https://github.com/galaxyproject/galaxy/archive/v15.07.tar.gz
tar -xzvf v15.07.tar.gz
rm v15.07.tar.gz
mv galaxy-15.07 galaxy
cd galaxy
sed 's/^#host = 127.0.0.1/host = 0.0.0.0/' config/galaxy.ini.sample > config/galaxy.ini
