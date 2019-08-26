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
	filename="./openemail-users.csv"
  while read -r line; do
		source ../openemail.conf
    row="$line"
    export ID=$(echo $row | cut -f1 -d ,) ; echo ${ID}
    export USER=$(echo $row | cut -f2 -d ,) ; echo ${USER}
    export FNAME=$(echo $row | cut -f3 -d ,) ; echo ${FNAME}
    export DOMAIN=$(echo $row | cut -f4 -d ,) ; echo ${DOMAIN}
    export EMAIL=$(echo $row | cut -f5 -d ,) ; echo ${EMAIL}
    export QUOTA=$(echo $row | cut -f6 -d ,) ; echo ${QUOTA}
    export PWHASH=$(echo $row | cut -f7 -d ,) ; echo ${PWHASH}
		docker exec -it $(docker ps -qf name=mysql) mysql -u${DBUSER} -p${DBPASS} ${DBNAME} -e "SET @ID=${ID};"
		docker exec -it $(docker ps -qf name=mysql) mysql -u${DBUSER} -p${DBPASS} ${DBNAME} -e "SET @USER='${USER}';"
		docker exec -it $(docker ps -qf name=mysql) mysql -u${DBUSER} -p${DBPASS} ${DBNAME} -e "SET @FNAME='${FNAME}';"
		docker exec -it $(docker ps -qf name=mysql) mysql -u${DBUSER} -p${DBPASS} ${DBNAME} -e "SET @DOMAIN='${DOMAIN}';"
		docker exec -it $(docker ps -qf name=mysql) mysql -u${DBUSER} -p${DBPASS} ${DBNAME} -e "SET @EMAIL='${EMAIL}';"
		docker exec -it $(docker ps -qf name=mysql) mysql -u${DBUSER} -p${DBPASS} ${DBNAME} -e "SET @QUOTA=${QUOTA};"
		docker exec -it $(docker ps -qf name=mysql) mysql -u${DBUSER} -p${DBPASS} ${DBNAME} -e "SET @PWHASH='${PWHASH}';"
		docker exec -it $(docker ps -qf name=mysql) mysql -u${DBUSER} -p${DBPASS} ${DBNAME} -e "INSERT INTO mailbox (username, password, name, quota, local_part, domain, attributes, active) VALUES (@EMAIL, @PWHASH, @FNAME, @QUOTA, @USER, @DOMAIN, '{\"force_pw_update\":\"0\",\"tls_enforce_in\":\"0\",\"tls_enforce_out\":\"0\",\"sogo_access\":\"1\",\"mailbox_format\":\"maildir:\",\"quarantine_notification\":\"never\"}', 1);"
    docker exec -it $(docker ps -qf name=mysql) mysql -u${DBUSER} -p${DBPASS} ${DBNAME} -e "INSERT INTO alias (id, address, goto, domain, active) VALUES (@ID, @EMAIL, @EMAIL, @DOMAIN, 1);"
	  docker exec -it $(docker ps -qf name=mysql) mysql -u${DBUSER} -p${DBPASS} ${DBNAME} -e "INSERT INTO quota2 (username, bytes, messages) VALUES (@EMAIL, 0, 0);"
    docker exec -it $(docker ps -qf name=mysql) mysql -u${DBUSER} -p${DBPASS} ${DBNAME} -e "INSERT INTO user_acl (username, spam_alias, tls_policy, spam_score, spam_policy, delimiter_action, syncjobs, eas_reset, sogo_profile_reset, quarantine, quarantine_attachments, quarantine_notification) VALUES (@EMAIL, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1);"
	  docker exec -it $(docker ps -qf name=mysql) mysql -u${DBUSER} -p${DBPASS} ${DBNAME} -e "INSERT INTO _sogo_static_view (c_uid, domain, c_name, c_password, c_cn, mail, aliases, ad_aliases, kind, multiple_bookings) VALUES (@EMAIL, @DOMAIN, @EMAIL, @PWHASH, @FNAME, @EMAIL, '', '', '', -1);"
	done < "$filename"
	echo "
User successfully added
"
else
	echo "Operation failed."
fi