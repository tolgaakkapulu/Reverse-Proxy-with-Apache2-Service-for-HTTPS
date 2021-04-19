#!/bin/bash

PROXY_PORT=9443
LOCAL_PORT=9200

VALIDITY=1825
COUNTRY_CODE="XX"
S="State_or_Province_Name"
L="Locality_Name"
O="Organization_Name"
OU="Organizational_Unit_Name"
CN=`hostname`
emailAddress="Email_Address"
SUBJECT="/C=$COUNTRY_CODE/ST=$S/L=$L/O=$O/OU=$OU/CN=$CN/emailAddress=$emailAddress"

CONF_FILE_PATH="/etc/httpd/conf.d/proxy-ssl-$CN.conf"
CONF_FILE_NAME=$(echo $CONF_FILE_PATH | awk -F'/' '{print $NF}')

echo -e """\e[34m
===========================================
|  Installing httpd and its dependencies  |
===========================================\e[0m"""

echo -e "\e[33m+\e[0m  \e[32myum install -y httpd\e[0m"
yum install -y httpd 2> /dev/null > tmp.file

echo -e "\e[33m+\e[0m  \e[32myum install -y mod_ssl\e[0m"
yum install -y mod_ssl 2> /dev/null > tmp.file

echo -e "\e[33m+\e[0m  \e[32myum install -y ca-certificates\e[0m"
yum install -y ca-certificates 2> /dev/null > tmp.file

echo -e "\n\e[33m+\e[0m  \e[32msystemctl enable httpd\e[0m"
systemctl enable httpd 2> /dev/null > tmp.file

echo -e "\e[33m+\e[0m  \e[32msystemctl restart httpd\e[0m"
systemctl restart httpd


echo -e """\e[34m
============================
|  Creating a Certificate  |
============================\e[0m"""

echo -e "\e[33m+\e[0m  \e[32mopenssl genrsa -out $CN.key 2048\e[0m"
openssl genrsa -out $CN.key 2048 2> /dev/null > tmp.file

echo -e "\e[33m+\e[0m  \e[32mopenssl req -nodes -new -key $CN.key -out $CN.csr -subj $SUBJECT\e[0m"
openssl req -nodes -new -key $CN.key -out $CN.csr -subj $SUBJECT

echo -e "\e[33m+\e[0m  \e[32mopenssl x509 -req -days $VALIDITY -in $CN.csr -signkey $CN.key -out $CN.crt\e[0m"
openssl x509 -req -days $VALIDITY -in $CN.csr -signkey $CN.key -out $CN.crt 2> /dev/null > tmp.file


mkdir /etc/httpd/ssl 2> /dev/null > tmp.file

echo -e "\n\e[33m+\e[0m  \e[32mmv $CN.* /etc/httpd/ssl/\e[0m"
mv $CN.* /etc/httpd/ssl/

echo -e "\e[33m+\e[0m  \e[32mupdate-ca-trust force-enable\e[0m"
update-ca-trust force-enable

echo -e "\e[33m+\e[0m  \e[32mcp /etc/httpd/ssl/$CN.crt /etc/pki/ca-trust/source/anchors/\e[0m"
cp /etc/httpd/ssl/$CN.crt /etc/pki/ca-trust/source/anchors/

echo -e "\e[33m+\e[0m  \e[32mupdate-ca-trust extract\e[0m"
update-ca-trust extract


echo "
Listen $PROXY_PORT https

<VirtualHost *:$PROXY_PORT>
        ServerName $CN

        ErrorLog /var/log/httpd/error_log
        CustomLog /var/log/httpd/access_log combined

        SSLEngine On
        SSLProtocol -all +TLSv1.2
        SSLCipherSuite EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:AES256+EDH
        SSLCertificateFile /etc/httpd/ssl/$CN.crt
        SSLCertificateKeyFile /etc/httpd/ssl/$CN.key

        <Location />
            ProxyPreserveHost On
            ProxyPass http://localhost:$LOCAL_PORT/
            ProxyPassReverse http://localhost:$LOCAL_PORT/
        </Location>
</VirtualHost>" > $CONF_FILE_PATH

echo -e "\n\e[33m+\e[0m  \e[33mThe $CONF_FILE_PATH file has been created.\e[0m"
echo "ServerName $CN" >> /etc/httpd/conf/httpd.conf

echo -e "\e[33m+\e[0m  \e[32msystemctl restart httpd\e[0m"
systemctl restart httpd


echo -e """\e[34m
============================
|  Settings are completed  |
============================\e[0m"""
echo -e "\e[33m+\e[0m  \e[32mcurl -XGET https://$CN:$PROXY_PORT\e[0m\n"
echo -e -n "\e[33m+\e[0m  \e[35mResult:\e[0m  "
curl -XGET https://$CN:$PROXY_PORT

rm -rf tmp.file
