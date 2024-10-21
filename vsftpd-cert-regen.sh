#!/usr/bin/env bash

# Author:   Rémi C. MIT License
# Purpose:  Generate (or renew) FTP self-signed certificate (vsftpd.pem + vsftpd.key) for 1 year

# NOTE: Path to .pem: /etc/ssl/certs    (perm 0755)
#       Path to .key: /etc/ssl/private  (perm 0600)
#       Make sure it corresponds to your distribution defaults



# globals
CERT_NAME="vsftpd.pem"
KEY_NAME="${CERT_NAME}.key"
CERT_PATH="/etc/ssl/certs"
KEY_PATH="/etc/ssl/private"
CURRENT_TIME=$(date +"%F %R:%S")
LAST_RUN="(first run)"


# detect ctrl+c to cancel operation
stty -echoctl           # hide "^C" when ctrl+c is detected
trap ctrl_c INT
function ctrl_c() {
    echo -e "\n\nCanceled (ctrl+c)"
    exit 1
}


# main
echo "Last cert creation: ${LAST_RUN}"
echo -e "Operation can be canceled with ctrl+c at any time\n"

read -n1 -p "Generate certificate now? [y/N] : " ANS
case ${ANS} in
    y|Y) [ -d ${CERT_PATH} ] || echo -e "WARNING: Missing folder ${CERT_PATH} && exit 1"
         [ -d ${KEY_PATH} ] || echo -e "WARNING: Missing folder ${KEY_PATH} && exit 1"
         sudo openssl req -x509 -nodes -days 365 -newkey rsa:4096 \
             -keyout ${KEY_PATH}/${KEY_NAME} \
             -out ${CERT_PATH}/${CERT_NAME}
         sudo chmod 644 ${CERT_PATH}/${CERT_NAME}
         sudo chmod 600 ${KEY_PATH}/${KEY_NAME}
         echo -e "\nCertificate created successfully"
         echo -e "\tCert:\t${CERT_PATH}/${CERT_NAME}\n\tKey:\t${KEY_PATH}/${KEY_NAME}"
         echo -e "\nCheck vsftpd.conf for matching paths";;
    *)   echo -e "\nCanceled"
         exit 1;;
esac


# update LAST_RUN variable to current time at every completed cert renewal
sed -i "0,/^LAST_RUN.*$/ s//LAST_RUN=\"${CURRENT_TIME}\"/" $0

#END
