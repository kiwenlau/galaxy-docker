#!/bin/bash

echo -e "\nbuild kiwenlau/galaxy-docker image...\n"
sudo docker build -t kiwenlau/galaxy-docker .

sudo docker rm -f galaxy &> galaxy

echo -e "\nstart galaxy container..."

# sudo docker run -it --name=galaxy kiwenlau/galaxy-docker bash

sudo docker run -it -d --name=galaxy -p 8080:8080 kiwenlau/galaxy-docker > /dev/null 

date

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

date

echo ""
