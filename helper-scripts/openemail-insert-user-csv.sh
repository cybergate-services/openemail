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

	echo "Inserting user into mailbox table"
	IFS=,
	while read id user fname domain email quota pwhash
  do
    echo "INSERT INTO mailbox (username, password, name, quota, local_part, domain, attributes, active) VALUES ('$email', '$pwhash', '$fname',  $quota, '$user', '$domain', '{\"force_pw_update\":\"0\",\"tls_enforce_in\":\"0\",\"tls_enforce_out\":\"0\",\"sogo_access\":\"1\",\"mailbox_format\":\"maildir:\",\"quarantine_notification\":\"never\"}', 1);"
	done < openemail-users.csv | docker-compose exec -T mysql-openemail mysql -u${DBUSER} -p${DBPASS} ${DBNAME} ;
	echo " mailbox table"

	echo "Inserting user into alias table"
	IFS=,
	while read id user fname domain email quota pwhash
  do
    echo "INSERT INTO alias (id, address, goto, domain, active) VALUES ($id, '$email', '$email', '$domain', 1);"
	done < openemail-users.csv | docker-compose exec -T mysql-openemail mysql -u${DBUSER} -p${DBPASS} ${DBNAME} ;
	echo "User is successfully inserted to alias table"

	echo "Inserting user into quota 2table"
	IFS=,
	while read id user fname domain email quota pwhash
  do
    echo "INSERT INTO quota2 (username, bytes, messages) VALUES ('$email', 0, 0);"
	done < openemail-users.csv | docker-compose exec -T mysql-openemail mysql -u${DBUSER} -p${DBPASS} ${DBNAME} ;
	echo "User is successfully inserted to quota2 table"

	echo "Inserting user into user_acl table"
	IFS=,
	while read id user fname domain email quota pwhash
  do
    echo "INSERT INTO user_acl (username, spam_alias, tls_policy, spam_score, spam_policy, delimiter_action, syncjobs, eas_reset, sogo_profile_reset, quarantine, quarantine_attachments, quarantine_notification) VALUES ('$email', 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1);"
	done < openemail-users.csv | docker-compose exec -T mysql-openemail mysql -u${DBUSER} -p${DBPASS} ${DBNAME} ;
	echo "User is successfully inserted to user_acl table"

	echo "User is inserting into _sogo_static_view table"
	IFS=,
	while read id user fname domain email quota pwhash
  do
    echo "INSERT INTO _sogo_static_view (c_uid, domain, c_name, c_password, c_cn, mail, aliases, ad_aliases, kind, multiple_bookings) VALUES ('$email', '$domain', '$email', '$pwhash', '$fname', '$email', '', '', '', -1);"
	done < openemail-users.csv | docker-compose exec -T mysql-openemail mysql -u${DBUSER} -p${DBPASS} ${DBNAME} ;
	echo "User is successfully inserted to _sogo_static_view table"

	echo "
All mailbox accounts successfully added to all required tables.
"
else
	echo "Operation canceled."
fi
