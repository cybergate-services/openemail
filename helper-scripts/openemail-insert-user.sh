#!/usr/bin/env bash
[[ -f openemail.conf ]] && source openemail.conf
[[ -f ../openemail.conf ]] && source ../openemail.conf

if [[ -z ${DBUSER} ]] || [[ -z ${DBPASS} ]] || [[ -z ${DBNAME} ]]; then
	echo "Cannot find openemail.conf, make sure this script is run from within the openemail folder."
	exit 1
fi

echo -n "Checking MySQL service... "
if [[ -z $(docker ps -qf name=mysql) ]]; then
	echo "failed"
	echo "MySQL (mysql) is not up and running, exiting..."
	exit 1
fi

echo "OK"
read -r -p "Are you sure you want to insert mailbox accounts? [y/N] " response
response=${response,,}    # tolower
if [[ "$response" =~ ^(yes|y)$ ]]; then
	echo -e "\nWorking, please wait..."
	docker exec -it $(docker ps -qf name=mysql) mysql -u${DBUSER} -p${DBPASS} ${DBNAME} -e "INSERT INTO mailbox (username, password, name, quota, local_part, domain, active) VALUES ('info@softlineglobal.com', '{SSHA256}4BrbE0bJqOcY//mYmqSbHCPjx+GyAYZ1NCnr50lFtl1lZDJmMDdiMGQ5NDkxMmRh', 'Softline Info',  5343543296, 'info', 'softlineglobal.com', 1);"
	echo "
User successfully added
"
else
	echo "Operation canceled."
fi
