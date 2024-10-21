#!/usr/bin/env bash
#Author:  Rémi C <lanxsatura>. MIT License.

#Purpose: configure `~/.lftprc` for automatic TLS connections
#         towards FTPES (explicit SSL/TLS) servers
#         using a self-signed certificate


#check if lftp is installed
$(which lftp) >/dev/null 2>&1 || echo "lftp is not installed" && exit 1

#check if ~/.lftp/certs folder is present
[ -d ~/.lftp/certs ] || mkdir -p ~/.lftp/certs

#create a backup of .lftprc if it already exists
if [ -f ~/.lftprc ]; then
    cp ~/.lftprc ~/.lftprc.backup.$(date +"%F-at-%R:%S")
else
    touch ~/.lftprc
fi

#static list of recommended options for secure TLS
LIST=(
        'set ssl:check-hostname no'
        'set ftp:ssl-auth TLS'
        'set ftp:ssl-force true'
        'set ftp:ssl-protect-list yes'
        'set ftp:ssl-protect-data yes'
        'set ftp:ssl-protect-fxp yes'
        'set ssl:verify-certificate no'
        'set ftps:initial-prot P'
    )

#verify the presence of each option in ~/.lftprc
#if not present, append to file
for opt in "${LIST[@]}"; do
    if [[ ! "$(grep -e "${opt}" ~/.lftprc)" ]]; then
        echo "${opt}" >> ~/.lftprc && echo "Added: ${opt}"
    fi
done

#END
