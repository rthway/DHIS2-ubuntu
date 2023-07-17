sudo dpkg-reconfigure tzdata
cd /var
sudo mkdir www
sudo mkdir www/dhis
cd www/dhis/
cd ~
sudo useradd dhis_tl -s /bin/false
sudo passwd dhis_tl
sudo mkdir /var/www/dhis/config
sudo chown dhis_tl:dhis_tl /var/www/dhis/config
sudo apt-get update -y
sudo apt-get install -y postgresql postgresql-contrib
sudo apt-get install postgis -y
sudo -u postgres createuser -SDRP dhis_tl
sudo -u postgres createdb -O dhis_tl dhis2 
sudo -u postgres psql -c "create extension postgis;" dhis2 
sudo -u postgres psql -c "create extension pg_trgm;" dhis2 

sudo -u dhis_tl nano /var/www/dhis/config/dhis.conf
# Hibernate SQL dialect
connection.dialect = org.hibernate.dialect.PostgreSQLDialect

# JDBC driver class
connection.driver_class = org.postgresql.Driver

# Database connection URL
connection.url = jdbc:postgresql:dhis2

# Database username
connection.username = dhis_tl

# Database password
connection.password = 123456

# Database schema behavior, can be validate, update, create, create-drop
connection.schema = update

# Encryption password (sensitive)
encryption.password = xxxx

sudo apt-get install openjdk-11-jdk -y
ls /usr/lib/jvm
sudo apt-get install tomcat9-user
cd /var/www/dhis/
sudo chown -R dhis_tl:dhis_tl /var/www/dhis/tomcat-dhis/
sudo nano /var/www/dhis/tomcat-dhis/bin/setenv.sh

#!/bin/sh
#

CATALINA_HOME=/usr/share/tomcat9

# Find the Java runtime and set JAVA_HOME
. /usr/libexec/tomcat9/tomcat-locate-java.sh

# Default Java options
if [ -z "$JAVA_OPTS" ]; then
    JAVA_OPTS="-Djava.awt.headless=true -XX:+UseG1GC"
fi

export JAVA_HOME='/usr/lib/jvm/java-11-openjdk-amd64/'
export JAVA_OPTS='-Xmx2000m -Xms1000m'
export DHIS2_HOME='/var/www/dhis/config'

sudo cat /var/www/dhis/tomcat-dhis/bin/setenv.sh
cd ~
sudo wget https://s3-eu-west-1.amazonaws.com/releases.dhis2.org/2.37/dhis.war
sudo mv dhis.war /var/www/dhis/tomcat-dhis/webapps/ROOT.war
sudo nano /var/www/dhis/tomcat-dhis/bin/startup.sh

#!/bin/sh
set -e

if [ "$(id -u)" -eq "0" ]; then
   echo "This script must NOT be run as root" 1>&2
   exit 1
fi

export CATALINA_BASE="/var/www/dhis/tomcat-dhis"
/usr/share/tomcat9/bin/startup.sh
echo "Tomcat started"

sudo -u dhis_tl /var/www/dhis/tomcat-dhis/bin/startup.sh

sudo ufw allow 8080/tcp

