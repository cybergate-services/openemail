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
  docker exec -it $(docker ps -qf name=mysql) mysql -u${DBUSER} -p${DBPASS} ${DBNAME} -e "INSERT INTO alias (id, address, goto, domain, active) VALUES (5, 'info@softlineglobal.com', 'info@softlineglobal.com', 'softlineglobal.com', 1);"
	docker exec -it $(docker ps -qf name=mysql) mysql -u${DBUSER} -p${DBPASS} ${DBNAME} -e "INSERT INTO quota2 (username, bytes, messages) VALUES ('info@softlineglobal.com', 0, 0);"
  docker exec -it $(docker ps -qf name=mysql) mysql -u${DBUSER} -p${DBPASS} ${DBNAME} -e "INSERT INTO user_acl (username, spam_alias, tls_policy, spam_score, spam_policy, delimiter_action, syncjobs, eas_reset, sogo_profile_reset, quarantine, quarantine_attachments, quarantine_notification) VALUES ('info@softlineglobal.com', 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1);"
	docker exec -it $(docker ps -qf name=mysql) mysql -u${DBUSER} -p${DBPASS} ${DBNAME} -e "INSERT INTO _sogo_static_view (c_uid, domain, c_name, c_password, c_cn, mail, aliases, ad_aliases, kind, multiple_bookings) VALUES ('info@softlineglobal.com', 'softlineglobal.com', 'info@softlineglobal.com', '{SSHA256}4BrbE0bJqOcY//mYmqSbHCPjx+GyAYZ1NCnr50lFtl1lZDJmMDdiMGQ5NDkxMmRh', 'Softline Info', 'info@softlineglobal.com', '', '', '', -1);"
	echo "
User successfully added
"
else
	echo "Operation canceled."
fi
