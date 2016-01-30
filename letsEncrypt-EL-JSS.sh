#!/bin/bash

########################## Variables ##########################
# Service name for systemctl
serviceName=jamf.tomcat7
# Location of Let's Encrypt
letsEncryptDir=/var/git/letsencrypt
# Add URL after /live/
certDir=/etc/letsencrypt/live/jss.example.com
# Location of JAVA Keytool
keytoolDir=/usr/bin/
# Domain Name
myDomain=jss.example.com
# Email Address
myEmail=sysadmins@example.com
# Primary Network Device
networkDevice=eth0
# Location of keystore (found in server.xml)
keystoreDir=/usr/local/jss/tomcat/TomcatSSLKeystore
# Password for keystore (found in server.xml)
keystorePass=changeit
# Test-only Cert (true || false)
testCert=true
# Backup Keystore (true || false)
backupKeystore=false
######################## Do Not Modify ########################

createIPtables () {
iptables -I INPUT -p tcp -m tcp --dport 9999 -j ACCEPT
iptables -t nat -I PREROUTING -i $networkDevice -p tcp -m tcp --dport 80 -j REDIRECT --to-ports 9999
}

removeIPtables () {
iptables -t nat -D PREROUTING -i $networkDevice -p tcp -m tcp --dport 80 -j REDIRECT --to-ports 9999
iptables -D INPUT -p tcp -m tcp --dport 9999 -j ACCEPT
}

# Update Let's Encrypt
cd $letsEncryptDir
git pull origin master

# Open IPtables
createIPtables

# Create cert (prod or test)
# test cert
if [ $testCert == true ]; then
./letsencrypt-auto certonly --standalone --test-cert --break-my-certs -d $myDomain --standalone-supported-challenges http-01 --http-01-port 9999 --renew-by-default --email $myEmail --agree-tos
# prod cert
elif [ $testCert == false ]; then
./letsencrypt-auto certonly --standalone -d $myDomain --standalone-supported-challenges http-01 --http-01-port 9999 --renew-by-default --email $myEmail --agree-tos
# error and quit
else
echo "ERROR: Type of Certificate not specified"
removeIPtables
exit 1
fi

# Close IPtables
removeIPtables

# Backup old keystore
if [ $backupKeystore == true ]; then
cp -R $keystoreDir "$keystoreDir".old
fi

# Remove old certs
$keytoolDir/keytool -delete -alias root -storepass $keystorePass -keystore $keystoreDir
$keytoolDir/keytool -delete -alias tomcat -storepass $keystorePass -keystore $keystoreDir
$keytoolDir/keytool -delete -alias cacert -storepass $keystorePass -keystore $keystoreDir

# Create P12
openssl pkcs12 -export -in $certDir/fullchain.pem -inkey $certDir/privkey.pem -out $certDir/cert_and_key.p12 -name tomcat -CAfile $certDir/chain.pem -caname root -password pass:$keystorePass

# Import P12 into keystore
$keytoolDir/keytool -importkeystore -srcstorepass $keystorePass -deststorepass $keystorePass -destkeypass $keystorePass -srckeystore $certDir/cert_and_key.p12 -srcstoretype PKCS12 -alias tomcat -keystore $keystoreDir
$keytoolDir/keytool -import -trustcacerts -alias root -deststorepass $keystorePass -file $certDir/chain.pem -noprompt -keystore $keystoreDir

# Restart Tomcat service
systemctl restart $serviceName
if [ $? != 0 ]; then
echo "failed to restart service"
exit 1
fi

# Exit cleanly
exit 0
