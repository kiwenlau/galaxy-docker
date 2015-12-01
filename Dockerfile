FROM ubuntu:14.04

MAINTAINER kiwenlau <kiwenlau@gmail.com>

WORKDIR /root

ADD install-galaxy.sh /root/install-galaxy.sh
RUN bash /root/install-galaxy.sh
