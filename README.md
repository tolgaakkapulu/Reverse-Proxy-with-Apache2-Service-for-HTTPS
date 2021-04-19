# Reverse Proxy with Apache2 Service for HTTPS

It provides the necessary **certificate creation** and **configurations** for converting **HTTP** ports to **HTTPS** with **Reverse Proxy** using **Apache2** in **CentOS** or **Ubuntu**.

The following parameters should be changed according to the ports to be applied. 
```
PROXY_PORT=9443
LOCAL_PORT=9200
```
***NOTE:** The default port of **Elasticsearch 9200**, was used as an example, and requests to port **9443** were routed to this port.*

The following parameters should be changed according to the certificate information to be used. 
```
VALIDITY=1825
COUNTRY_CODE="XX"
S="State_or_Province_Name"
L="Locality_Name"
O="Organization_Name"
OU="Organizational_Unit_Name"
emailAddress="Email_Address"
```

### Usage

**CentOS:** ```bash reverse_proxy_https_httpd_centos.sh```
<br><br>
<img src="https://github.com/tolgaakkapulu/Reverse-Proxy-with-Apache2-Service-for-HTTPS/blob/main/centos.png"><br>

**Ubuntu:** ```bash reverse_proxy_https_apache2_ubuntu.sh```
<br><br>
<img src="https://github.com/tolgaakkapulu/Reverse-Proxy-with-Apache2-Service-for-HTTPS/blob/main/ubuntu.png">

