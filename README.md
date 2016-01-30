# Let's Encrypt for JSS
**Implementation of Let's Encrypt SSL for the JAMFSoftwareServer on RHEL/CentOS 7**

There are 3 components to this solution:

1. Let's Encrypt
2. Script
3. Cronjob (only for automatic renewal)

# Install Let's Encrypt
**The directories listed below can be changed as desired - ensure you update the script with the new location**
```bash
yum install git -y
mkdir -p /var/git/letsencrypt
cd /var/git
git clone https://github.com/letsencrypt/letsencrypt
cd letsencrypt
```
# Install Script
**The directory listed below can be changed as desired**
```bash
mkdir -p /root/bin/
cd /root/bin
git clone git@github.com:sonofiron/letsEncrypt-for-JSS.git
cd letsEncrypt-for-JSS
```
# Configure Script
**Modify the variables as necessary**
```bash
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
```

# Install Cronjob
**The example below would renew the certificate every 2 months**
```bash
30 03 01 */2 * /path/to/letsEncrypt-EL-JSS.sh
```

# Special Thanks
Ivan Tichy provided the foundation [on his blog](http://blog.ivantichy.cz/blogpost/view/74).
