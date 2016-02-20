#!/bin/bash

service mysql start

/root/galaxy/run.sh --daemon

tail -f /root/galaxy/paster.log