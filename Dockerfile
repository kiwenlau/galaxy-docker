FROM ubuntu:14.04

MAINTAINER kiwenlau <kiwenlau@gmail.com>

WORKDIR /root

# install vim, wget, python and mysql
RUN apt-get update && apt-get install -y vim wget python mysql-server samtools
 
# install galaxy v15.10.1
RUN wget https://github.com/galaxyproject/galaxy/archive/v15.10.1.tar.gz && \
	tar -xzvf v15.10.1.tar.gz && \
	rm v15.10.1.tar.gz && \
	mv galaxy-15.10.1 galaxy

# ADD tool_data_table_conf.xml /root/galaxy/config/tool_data_table_conf.xml
# ADD tool_sheds_conf.xml /root/galaxy/config/tool_sheds_conf.xml

ADD configure-galaxy.sh /tmp/configure-galaxy.sh
RUN bash /tmp/configure-galaxy.sh

ADD initialize-galaxy.sh /root/initialize-galaxy.sh
RUN bash /root/initialize-galaxy.sh

ADD start-galaxy.sh /root/start-galaxy.sh
CMD ["/root/start-galaxy.sh"]

# sudo docker build -t kiwenlau/galaxy-docker .