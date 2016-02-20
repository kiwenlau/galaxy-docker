#/bin/bash

# configure mysql
echo "[mysql]\ndefault-character-set=utf8\n" > /etc/mysql/conf.d/mysql_default_character_set_utf8.cnf
locale-gen en_US.UTF-8 && update-locale LANG=en_US.UTF-8
mysql_install_db
mysqld_safe &
sleep 2
mysql -uroot -e "create database galaxy;"
mysql -uroot -e "create user 'galaxy'@'localhost' identified by 'galaxy';" 
mysql -uroot -e "grant all on galaxy.* to 'galaxy'@'localhost';" 
mysql -uroot -e "SET PASSWORD FOR galaxy@localhost=PASSWORD('galaxy');"

WORK_DIRECTORY=/opt/workdir

# configure galaxy
sed 's/^#host = 127.0.0.1/host = 0.0.0.0/' /root/galaxy/config/galaxy.ini.sample > /root/galaxy/config/galaxy.ini
sed -i "s@^#file_path = database/files@file_path = $WORK_DIRECTORY/galaxy_files@" /root/galaxy/config/galaxy.ini
sed -i "s@^#new_file_path = database/tmp@new_file_path = $WORK_DIRECTORY/database/tmp@" galaxy/config/galaxy.ini
sed -i "s@^#job_working_directory = database/job_working_directory@job_working_directory = $WORK_DIRECTORY/database/job_working_directory@" galaxy/config/galaxy.ini
sed -i 's$^#database_connection = sqlite:///./database/universe.sqlite?isolation_level=IMMEDIATE$database_connection = mysql://galaxy:galaxy@localhost:3306/galaxy?unix_socket=/var/run/mysqld/mysqld.sock$' /root/galaxy/config/galaxy.ini
sed -i 's/^#database_engine_option_pool_recycle = -1/database_engine_option_pool_recycle = 7200/' /root/galaxy/config/galaxy.ini
sed -i 's$^#tool_dependency_dir = None$tool_dependency_dir = ../tool_dependency$' /root/galaxy/config/galaxy.ini
sed -i 's/^#allow_user_dataset_purge = False/allow_user_dataset_purge = True/' /root/galaxy/config/galaxy.ini