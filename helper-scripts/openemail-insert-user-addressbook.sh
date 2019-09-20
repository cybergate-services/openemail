#!/usr/bin/env bash
$1=MAILBOX
$2=ADDRESBOOKCSV
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
read -r -p "Are you sure you want to insert into addressbook? [y/N] " response
ID=$(od -An -N1 -i /dev/random)
response=${response,,}    # tolower
if [[ "$response" =~ ^(yes|y)$ ]]; then
	echo -e "\nWorking, please wait..."
	echo "Inserting into sogo_folder_info table"

	echo "INSERT INTO sogo_folder_info (c_folder_id, c_path, c_path1, c_path2, c_path3, c_path4, c_foldername, c_location, c_quick_location, c_acl_location, c_folder_type) VALUES ('$ID', '/Users/$MAILBOX/Contacts/personal', 'Users', '$MAILBOX', 'Contacts', 'personal', 'Personal Address Book', 'mysql://openemail:8Oe6NlPrZ5UDmqfeFQwYCBlOMNHb@%2Fvar%2Frun%2Fmysqld%2Fmysqld.sock/openemail/sogoamilasof0013a849ab2', 'mysql://openemail:8Oe6NlPrZ5UDmqfeFQwYCBlOMNHb@%2Fvar%2Frun%2Fmysqld%2Fmysqld.sock/openemail/sogoamilasof0013a849ab2_quick', 'mysql://openemail:8Oe6NlPrZ5UDmqfeFQwYCBlOMNHb@%2Fvar%2Frun%2Fmysqld%2Fmysqld.sock/openemail/sogoamilasof0013a849ab2_acl', 'Contact');" | docker-compose exec -T mysql-openemail mysql -u${DBUSER} -p${DBPASS} ${DBNAME}

  echo "Inserting into sogo_quick_contact table"

	IFS=,
	while read fname lname dsplname email
  do
    echo "INSERT INTO sogo_quick_contact (c_folder_id, c_name, c_givenname, c_cn, c_sn, c_screenname, c_l, c_mail, c_o, c_ou, c_telephonenumber, c_categories, c_component, c_hascertificate) VALUES ('$ID', '48-5D837D00-D-153063E0.vcf', '$fname', '$dsplname', '$lname', '', NULL, '$email', '', '', NULL, NULL, 'vcard', '0');"
	done < $ADDRESBOOKCSV | docker-compose exec -T mysql-openemail mysql -u${DBUSER} -p${DBPASS} ${DBNAME} ;
	echo "All addressbook entriess successfully added to sogo_quick_contact table."
else
	echo "Operation canceled."
fi
