#!/bin/sh

log_file='/tmp/galaxy.log'
pid_file='/tmp/galaxy.pid'

/root/galaxy/run.sh --daemon --log-file=$log_file --pid-file=$pid_file

galaxy_initialize_pid=`cat $pid_file`

while : ; do
    tail -n 2 $log_file | grep -q "Starting server in PID $galaxy_initialize_file"
    if [ $? -eq 0 ] ; then
        echo "Galaxy is running."
        break
    fi
done

exit_code=$?

if [ $exit_code != 0 ] ; then
    exit $exit_code
fi

/root/galaxy/run.sh --stop-daemon --log-file=$log_file --pid-file=$pid_file