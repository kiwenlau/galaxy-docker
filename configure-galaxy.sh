#/bin/bash

# configure mysql
mysql_install_db
mysqld_safe &
sleep 2
mysql -uroot -e "create database galaxy;"
mysql -uroot -e "create user 'galaxy'@'localhost' identified by 'galaxy';" 
mysql -uroot -e "grant all on galaxy.* to 'galaxy'@'localhost';" 
mysql -uroot -e "SET PASSWORD FOR galaxy@localhost=PASSWORD('galaxy');"

# configure galaxy
sed 's/^#host = 127.0.0.1/host = 0.0.0.0/' /root/galaxy/config/galaxy.ini.sample > /root/galaxy/config/galaxy.ini
sed -i "s@^#file_path = database/files@file_path = /opt/workdir/galaxy_files@" /root/galaxy/config/galaxy.ini
sed -i "s@^#new_file_path = database/tmp@new_file_path = /opt/workdir/database/tmp@" galaxy/config/galaxy.ini
sed -i "s@^#job_working_directory = database/job_working_directory@job_working_directory = /opt/workdir/database/job_working_directory@" galaxy/config/galaxy.ini
sed -i 's$^#database_connection = sqlite:///./database/universe.sqlite?isolation_level=IMMEDIATE$database_connection = mysql://galaxy:galaxy@localhost:3306/galaxy?unix_socket=/var/run/mysqld/mysqld.sock$' /root/galaxy/config/galaxy.ini
sed -i 's/^#database_engine_option_pool_recycle = -1/database_engine_option_pool_recycle = 7200/' /root/galaxy/config/galaxy.ini
sed -i 's$^#tool_dependency_dir = None$tool_dependency_dir = ../tool_dependency$' /root/galaxy/config/galaxy.ini
sed -i 's/^#allow_user_dataset_purge = False/allow_user_dataset_purge = True/' /root/galaxy/config/galaxy.ini

mv /tmp/config/job_conf.xml /root/galaxy/config/job_conf.xml
mv /tmp/config/tool_conf.xml /root/galaxy/config/tool_conf.xml
mkdir /root/galaxy/tools/swarm
mv /tmp/config/cufflinks_wrapper.xml /root/galaxy/tools/swarm/cufflinks_wrapper.xml
mv /tmp/config/cuff_macros.xml /root/galaxy/tools/swarm/cuff_macros.xml
mv /tmp/config/tophat2_wrapper.xml /root/galaxy/tools/swarm/tophat2_wrapper.xml
mv /tmp/config/tophat_macros.xml /root/galaxy/tools/swarm/tophat_macros.xml
mv /tmp/config/cuffdiff_wrapper.xml /root/galaxy/tools/swarm/cuffdiff_wrapper.xml
mv /tmp/config/cuffmerge_wrapper.xml /root/galaxy/tools/swarm/cuffmerge_wrapper.xml

mv /tmp/config/swarm.py /root/galaxy/lib/galaxy/jobs/runners/swarm.py
