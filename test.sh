#!/bin/bash

sudo docker build -t kiwenlau/galaxy-docker .

sudo docker run -it kiwenlau/galaxy-docker bash