FROM ubuntu:14.04

MAINTAINER kiwenlau <kiwenlau@gmail.com>

WORKDIR /root

# install and initialize galaxy
ADD install-galaxy.sh /root/install-galaxy.sh
ADD initialize-galaxy.sh /root/initialize-galaxy.sh
RUN bash /root/install-galaxy.sh
RUN bash /root/initialize-galaxy.sh

ADD start-galaxy.sh /root/start-galaxy.sh
CMD ["/root/start-galaxy.sh"]

# sudo docker build -t kiwenlau/galaxy-docker .