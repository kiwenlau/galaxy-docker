#!/bin/bash

sudo docker build -t kiwenlau/galaxy-docker .

sudo docker rm -f galaxy &> galaxy

sudo docker run -it -d --name=galaxy -p 8080:8080 kiwenlau/galaxy-docker 

# check the status of galaxy
echo -e "\nchecking the status of galaxy, please wait..."
for (( i = 0; i < 120; i++ )); do
	galaxy_logs=`docker logs galaxy | grep PID`
	if [[ $galaxy_logs ]]; then
		echo -e "\ngalaxy is running"
		break
	fi
	sleep 1
done

echo ""