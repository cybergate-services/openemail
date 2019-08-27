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

	echo "done"
	IFS=,
	while read id user fname domain email quota pwhash
  do
    echo "INSERT INTO mailbox (username, password, name, quota, local_part, domain, attributes, active) VALUES ('$email', '$fwhash', '$fname',  $quota, '$user', '$domain', '{\"force_pw_update\":\"0\",\"tls_enforce_in\":\"0\",\"tls_enforce_out\":\"0\",\"sogo_access\":\"1\",\"mailbox_format\":\"maildir:\",\"quarantine_notification\":\"never\"}', 1);"
	done < openemail-users.csv | docker exec -it $(docker ps -qf name=mysql) mysql -u${DBUSER} -p${DBPASS} ${DBNAME} -e;
	echo "finish"
	echo "
User successfully added
"
else
	echo "Operation canceled."
fi
