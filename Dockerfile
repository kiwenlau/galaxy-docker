FROM ubuntu:14.04

MAINTAINER kiwenlau <kiwenlau@gmail.com>

WORKDIR /root

ADD install-galaxy.sh /tmp/install-galaxy.sh
RUN sh /tmp/install-galaxy.sh
