#!/bin/bash

# Configure timezone
sudo dpkg-reconfigure tzdata

# add user dhis_tl on server
sudo useradd dhis_tl -s /bin/false

# set user password for dhis_tl
sudo passwd dhis_tl

# Create directories and user
sudo mkdir -p /var/www/dhis/config
sudo chown -R dhis_tl:dhis_tl /var/www/dhis

# Update and install packages
sudo apt-get update -y
sudo apt-get install -y postgresql postgresql-contrib
sudo apt-get install -y postgis
sudo apt-get install -y openjdk-11-jdk
sudo apt-get install -y tomcat9-user

# Create PostgreSQL user and database
sudo -u postgres createuser -SDRP dhis_tl
sudo -u postgres createdb -O dhis_tl dhis2
sudo -u postgres psql -c "create extension postgis;" dhis2
sudo -u postgres psql -c "create extension btree_gin;" dhis2
sudo -u postgres psql -c "create extension pg_trgm;" dhis2

# Configure DHIS2 properties
sudo -u dhis_tl tee -a /var/www/dhis/config/dhis.conf <<EOF
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
EOF

# Create Tomcat instance
cd /var/www/dhis
sudo tomcat9-instance-create tomcat-dhis
sudo chown -R dhis_tl:dhis_tl /var/www/dhis/tomcat-dhis/

# Configure Tomcat environment
sudo tee /var/www/dhis/tomcat-dhis/bin/setenv.sh <<EOF
#!/bin/sh
#

CATALINA_HOME=/usr/share/tomcat9

# Find the Java runtime and set JAVA_HOME
. /usr/libexec/tomcat9/tomcat-locate-java.sh

# Default Java options
if [ -z "\$JAVA_OPTS" ]; then
    JAVA_OPTS="-Djava.awt.headless=true -XX:+UseG1GC"
fi

export JAVA_HOME='/usr/lib/jvm/java-11-openjdk-amd64/'
JAVA_OPTS='-Xms4000m -Xmx7000m'
export DHIS2_HOME='/var/www/dhis/config'
EOF

# Download and deploy DHIS2 WAR file
cd ~
sudo wget https://s3-eu-west-1.amazonaws.com/releases.dhis2.org/2.40/dhis.war
sudo mv dhis.war /var/www/dhis/tomcat-dhis/webapps/ROOT.war

# Start Tomcat
sudo tee /var/www/dhis/tomcat-dhis/bin/startup.sh <<EOF
#!/bin/sh
set -e

if [ "\$(id -u)" -eq "0" ]; then
  echo "This script must NOT be run as root" 1>&2
  exit 1
fi

export CATALINA_BASE="/var/www/dhis/tomcat-dhis"
/usr/share/tomcat9/bin/startup.sh
echo "Tomcat started"
EOF

# Firewall setup 
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 8080/tcp
sudo ufw reload

# Start Tomcat as the dhis_tl user
sudo -u dhis_tl /var/www/dhis/tomcat-dhis/bin/startup.sh

