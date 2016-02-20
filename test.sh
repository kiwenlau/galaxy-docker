#!/bin/bash

sudo docker build -t kiwenlau/galaxy-docker .

sudo docker run -it -d kiwenlau/galaxy-docker 