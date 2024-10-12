#!/usr/bin/env bash

# Author:  Rémi C <lanxsatura>. MIT License.

# Purpose: lftp wrapper to connect to self-signed FTPES (explicit TLS)
#       * always checks for recommended options at execution time
#       * if a cert is accepted (1st time): auto configuration
#       * detects changes in certs (show diff, prompts user)
#       * run without argument (no leak of username or password)

# In case of a Certificate Authority (CA), manual configuration is required:
#       (1) Import CA to trusted db, (2) set ssl:check-hostname yes, (3) set ssl:verify-certificate yes,
#       (4) set ssl:ca-file "/etc/ssl/certs/ca-certificates.crt"


USRID="$(whoami)"
LFTPRC="/home/${USRID}/.lftprc"
CERT_DIR="/home/${USRID}/.lftp/certs"


validate_tls_conf () {
    LIST=(
        'set ssl:check-hostname no'
        'set ftp:ssl-auth TLS'
        'set ftp:ssl-force true'
        'set ftp:ssl-protect-list yes'
        'set ftp:ssl-protect-data yes'
        'set ftp:ssl-protect-fxp yes'
        'set ssl:verify-certificate no'
        'set ftps:initial-prot P'
        'set net:timeout 10'
    )

    #if they don't exist, create ~/.lftprc and ~/.lftp/certs/
    [ -f ${LFTPRC} ] || touch ${LFTPRC}
    [ -d ${CERT_DIR} ] || mkdir -p ${CERT_DIR}

    #check if LIST elements are present in ~/.lftprc
    for opt in "${LIST[@]}"; do
        if [[ ! "$(grep -e "${opt}" ${LFTPRC})" ]]; then
            echo "${opt}" >> ${LFTPRC}
        fi
    done
}


confirm_conn () {
    read -n1 -p "Connect now [y/n]? " ANS
    case ${ANS} in
        y|Y)    echo -e "\n" && lftp -p ${PORT} ${IP};;
        *)      echo -e "\n\nConnect later with ->\tlftp -p ${PORT} ${IP}" && exit 0;;
    esac
}


compare_cert () {
        #compare ${CERT} with ${CERT}.new
        sed -ne '/-----BEGIN CERTIFICATE-----/,/-----END CERTIFICATE-----/p' ${CERT}.info.new > ${CERT}.new
        if ! [[ $(openssl x509 -noout -modulus -in ${CERT} | openssl md5) == $(openssl x509 -noout -modulus -in ${CERT}.new | openssl md5) ]]; then
            diff -u ${CERT}.info ${CERT}.info.new
            echo -e "\nWARNING: Cert has changed! (Check diff above)\n"
            read -n1 -p "Accept new cert [y/n] ? " ANS
            case ${ANS} in
                y|Y)    mv ${CERT}.new ${CERT} && mv ${CERT}.info.new ${CERT}.info;;
                *)      rm ${CERT}.new ${CERT}.info.new && echo -e "\nCanceled. Exit" && exit 0;;
            esac
        else
            rm ${CERT}.new ${CERT}.info.new
        fi
}


print_cert () {
        while read line; do
            echo "${line}"
        done < ${CERT}
}


check_cert_path_in_lftprc () {
    if ! $(grep "${CERT}" ${LFTPRC}); then
        echo "set ssl:cert-file \"${CERT}\"" >> ${LFTPRC}
        echo -e "Cert path added to ${LFTPRC}\n"
        echo ''
    fi
}


#main
validate_tls_conf
read -p "FTP domain or IP: " IP
read -p "Port (default 21): " PORT
#default port set to 21
PORT=${PORT:-21}
CERT="${CERT_DIR}/${IP}.crt"
echo ''

#try connection
openssl s_client -connect ${IP}:${PORT} -starttls ftp -showcerts >/dev/null 2>&1 <<< "Q" > ${CERT}.info.new
if [ "$?" -ne "0" ]; then
    echo "ERROR: Connection failed. Check IP or PORT"
    rm ${CERT}.info.new
    exit 1
else
    #if ${CERT}.info doesn't exist, create it
    if [ ! -f ${CERT}.info ]; then
        mv ${CERT}.info.new ${CERT}.info
        #generate ${CERT} from ${CERT}.info
        sed -ne '/-----BEGIN CERTIFICATE-----/,/-----END CERTIFICATE-----/p' ${CERT}.info > ${CERT}
        echo "Cert saved in ${CERT}"
        rm ${CERT}.new
        print_cert 
        echo ''
        check_cert_path_in_lftprc
        confirm_conn
    else
        compare_cert
        check_cert_path_in_lftprc
        lftp -p ${PORT} ${IP}
    fi
fi

#END
