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

CONF_FILE_PATH="/etc/apache2/sites-available/proxy-ssl-$CN.conf"
CONF_FILE_NAME=$(echo $CONF_FILE_PATH | awk -F'/' '{print $NF}')

echo -e """\e[34m
=============================================
|  Installing apache2 and its dependencies  |
=============================================\e[0m"""

echo -e "\e[33m+\e[0m  \e[32mapt-get install -y apache2\e[0m"
apt-get install -y apache2 2> /dev/null > tmp.file

echo -e "\e[33m+\e[0m  \e[32mapt-get install -y libxml2-dev\e[0m"
apt-get install -y libxml2-dev 2> /dev/null > tmp.file

echo -e "\e[33m+\e[0m  \e[32mapt-get install -y build-essential\e[0m"
apt-get install -y build-essential 2> /dev/null > tmp.file

echo -e "\n\e[33m+\e[0m  \e[32msystemctl enable apache2\e[0m"
systemctl enable apache2 2> /dev/null > tmp.file

echo -e "\e[33m+\e[0m  \e[32msystemctl restart apache2\e[0m"
systemctl restart apache2

echo -e "\e[33m+\e[0m  \e[32mupdate-rc.d apache2 defaults\e[0m"
update-rc.d apache2 defaults


echo -e """\e[34m
=========================================
|  apache2 modules are being activated  |
=========================================\e[0m"""

A2ENMOD_MODULES=("a2enmod" "a2enmod proxy" "a2enmod proxy_http" "a2enmod proxy_ajp" "a2enmod rewrite" "a2enmod deflate" "a2enmod headers" "a2enmod proxy_balancer" "a2enmod proxy_connect" "a2enmod proxy_html" "a2enmod xml2enc" "a2enmod ssl")

for A2ENMOD_MODULE in "${A2ENMOD_MODULES[@]}"
do
	echo -e "\e[33m+\e[0m  \e[32m$A2ENMOD_MODULE\e[0m"
	echo "" | $A2ENMOD_MODULE 2> /dev/null > tmp.file
done

echo -e "\n\e[33m+\e[0m  \e[32ma2dissite 000-default\e[0m"
a2dissite 000-default 2> /dev/null > tmp.file
echo -e "\e[33m+\e[0m  \e[32msystemctl restart apache2\e[0m"
systemctl restart apache2


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

mkdir /etc/apache2/ssl 2> /dev/null > tmp.file

echo -e "\n\e[33m+\e[0m  \e[32mmv $CN.* /etc/apache2/ssl/\e[0m"
mv $CN.* /etc/apache2/ssl/

echo -e "\e[33m+\e[0m  \e[32mcat /etc/apache2/ssl/$CN.crt >> /etc/ssl/certs/ca-certificates.crt\e[0m"
cat /etc/apache2/ssl/$CN.crt >> /etc/ssl/certs/ca-certificates.crt

echo "
Listen $PROXY_PORT https

<VirtualHost *:$PROXY_PORT>
        ServerName $CN
		
        ErrorLog /var/log/apache2/error.log
        CustomLog /var/log/apache2/access.log combined
		
        SSLEngine On
        SSLProtocol -all +TLSv1.2
		SSLCipherSuite EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:AES256+EDH
        SSLCertificateFile /etc/apache2/ssl/$CN.crt
        SSLCertificateKeyFile /etc/apache2/ssl/$CN.key
		
        ProxyPreserveHost On
        ProxyPass / http://localhost:$LOCAL_PORT/
        ProxyPassReverse / http://localhost:$LOCAL_PORT/
</VirtualHost>" > $CONF_FILE_PATH

echo -e "\n\e[33m+\e[0m  \e[33mThe $CONF_FILE_PATH file has been created.\e[0m"
echo "ServerName $CN" >> /etc/apache2/apache2.conf

echo -e "\e[33m+\e[0m  \e[32ma2ensite $CONF_FILE_NAME\e[0m"
a2ensite $CONF_FILE_NAME 2> /dev/null > tmp.file

echo -e "\e[33m+\e[0m  \e[32msystemctl reload apache2\e[0m"
systemctl reload apache2

echo -e "\e[33m+\e[0m  \e[32msystemctl restart apache2\e[0m"
systemctl restart apache2


echo -e """\e[34m
============================
|  Settings are completed  |
============================\e[0m"""
echo -e "\e[33m+\e[0m  \e[32mcurl -XGET https://$CN:$PROXY_PORT\e[0m\n"
echo -e -n "\e[33m+\e[0m  \e[35mResult:\e[0m  "
curl -XGET https://$CN:$PROXY_PORT

rm -rf tmp.file
