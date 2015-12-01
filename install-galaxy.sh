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

install_log='/root/galaxy_install.log'

./run.sh --daemon --log-file=$install_log --pid-file=galaxy_install.pid

galaxy_install_pid=`cat galaxy_install.pid`
while : ; do
    tail -n 2 $install_log | grep -q "Starting server in PID $galaxy_install_pid"
    if [ $? -eq 0 ] ; then
        echo "Galaxy is running."
        break
    fi
done

exit_code=$?

if [ $exit_code != 0 ] ; then
    exit $exit_code
fi

./run.sh --stop-daemon --log-file=$install_log --pid-file=galaxy_install.pid

