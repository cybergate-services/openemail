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
	for row in $(cat ./openemail-users.csv)
	do
		export ID=$(echo $row | cut -f1 -d ,)
		export USER=$(echo $row | cut -f2 -d ,)
		export FNAME=$(echo $row | cut -f3 -d ,)
		export DOMAIN=$(echo $row | cut -f4 -d ,)
		export EMAIL=$(echo $row | cut -f5 -d ,)
		export QUOTA=$(echo $row | cut -f6 -d ,)
		export PWHASH=$(echo $row | cut -f7 -d ,)
		docker exec -it $(docker ps -qf name=mysql) mysql -u${DBUSER} -p${DBPASS} ${DBNAME} -e "SET @ID=${ID};SET @USER='${USER}';SET @FNAME='${FNAME}';SET @DOMAIN='${DOMAIN}';SET @EMAIL='${EMAIL}';SET @QUOTA=${QUOTA};SET @PWHASH='${PWHASH}';"
		docker exec -it $(docker ps -qf name=mysql) mysql -u${DBUSER} -p${DBPASS} ${DBNAME} -e "INSERT INTO mailbox (username, password, name, quota, local_part, domain, attributes, active) VALUES (@EMAIL, @PWHASH, @FNAME, @QUOTA, @USER, @DOMAIN, '{\"force_pw_update\":\"0\",\"tls_enforce_in\":\"0\",\"tls_enforce_out\":\"0\",\"sogo_access\":\"1\",\"mailbox_format\":\"maildir:\",\"quarantine_notification\":\"never\"}', 1);"
    docker exec -it $(docker ps -qf name=mysql) mysql -u${DBUSER} -p${DBPASS} ${DBNAME} -e "INSERT INTO alias (id, address, goto, domain, active) VALUES (@ID, @EMAIL, @EMAIL, @DOMAIN, 1);"
	  docker exec -it $(docker ps -qf name=mysql) mysql -u${DBUSER} -p${DBPASS} ${DBNAME} -e "INSERT INTO quota2 (username, bytes, messages) VALUES (@EMAIL, 0, 0);"
    docker exec -it $(docker ps -qf name=mysql) mysql -u${DBUSER} -p${DBPASS} ${DBNAME} -e "INSERT INTO user_acl (username, spam_alias, tls_policy, spam_score, spam_policy, delimiter_action, syncjobs, eas_reset, sogo_profile_reset, quarantine, quarantine_attachments, quarantine_notification) VALUES (@EMAIL, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1);"
	  docker exec -it $(docker ps -qf name=mysql) mysql -u${DBUSER} -p${DBPASS} ${DBNAME} -e "INSERT INTO _sogo_static_view (c_uid, domain, c_name, c_password, c_cn, mail, aliases, ad_aliases, kind, multiple_bookings) VALUES (@EMAIL, @DOMAIN, @EMAIL, @PWHASH, @FNAME, @EMAIL, '', '', '', -1);"
	done
	echo "
User successfully added
"
else
	echo "Operation failed."
fi
