FROM ubuntu:14.04

MAINTAINER kiwenlau <kiwenlau@gmail.com>

WORKDIR /root

# install vim, wget, python and mysql
RUN apt-get update && apt-get install -y vim wget python mysql-server
 
# install galaxy v15.10.1
RUN wget https://github.com/galaxyproject/galaxy/archive/v15.10.1.tar.gz && \
	tar -xzvf v15.10.1.tar.gz && \
	rm v15.10.1.tar.gz && \
	mv galaxy-15.10.1 galaxy

ADD config/* /tmp/config/
ADD configure-galaxy.sh /tmp/configure-galaxy.sh
RUN bash /tmp/configure-galaxy.sh

ADD initialize-galaxy.sh /root/initialize-galaxy.sh
RUN bash /root/initialize-galaxy.sh

RUN apt-get install -y samtools

RUN apt-get -y install make g++ gfortran openjdk-6-jdk subversion libblas-dev liblapack-dev libatlas-base-dev zlib1g-dev python-dev python-scipy

ADD start-galaxy.sh /root/start-galaxy.sh
CMD ["/root/start-galaxy.sh"]

# sudo docker build -t kiwenlau/galaxy-docker .