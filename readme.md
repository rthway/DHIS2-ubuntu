## Server specifications
DHIS2 is a database intensive application and requires that your server has an appropriate amount of RAM, number of CPU cores and a fast disk. These recommendations should be considered as rules-of-thumb and not exact measures. DHIS2 scales linearly on the amount of RAM and number of CPU cores so the more you can afford, the better the application will perform.

RAM: At least 2 GB for a small instance, 12 GB for a medium instance, 64 GB or more for a large instance.
CPU cores: 4 CPU cores for a small instance, 8 CPU cores for a medium instance, 16 CPU cores or more for a large instance.
Disk: SSD is recommeded as storage device. Minimum read speed is 150 Mb/s, 200 Mb/s is good, 350 Mb/s or better is ideal. At least 100 GB storage space is recommended, but will depend entirely on the amount of data which is contained in the data value tables. Analytics tables require a significant amount of storage space. Plan ahead and ensure that your server can be upgraded with more disk space as needed.

## Software requirements
Later DHIS2 versions require the following software versions to operate.

An operating system for which a Java JDK or JRE version 8 or 11 exists. Linux is recommended.
Java JDK. OpenJDK is recommended.
For DHIS 2 version 2.38 and later, JDK 11 is required.
For DHIS 2 version 2.35 and later, JDK 11 is recommended and JDK 8 or later is required.
For DHIS 2 versions older than 2.35, JDK 8 is required.
PostgreSQL database version 9.6 or later. A later PostgreSQL version such as version 14 is recommended.
PostGIS database extension version 2.2 or later.
Tomcat servlet container version 8.5.50 or later, or other Servlet API 3.1 compliant servlet containers.
Cluster setup only (optional): Redis data store version 4 or later.
## Server setup
We would like to setup DHIS2 under the /var/www/ directory instead of /home/dhis directory. Before that we created a subdomain mydomain.com and configured virtural host.

## Step-1: Basic configuration
1.1 Setting server time zone by invoking the below and following the instructions.



    sudo dpkg-reconfigure tzdata
Create a new directory:

 

    sudo mkdir /var/www/dhis 
If you found ‘can not create director’ error then please create the following www directory as:


     cd /var 
     sudo mkdir www 
     cd ~ 
Run again:


     sudo mkdir /var/www/dhis
Create a new user ‘dhis_tl’




    sudo useradd dhis_tl -s /bin/false

1.2 Then to set the password for your account invoke:



    sudo passwd dhis_tl
Make sure you set a strong password with random characters. For this tutorial, I set password ‘ROSHAN’.

1.3 Creating the configuration directory:

Start by creating a suitable directory for the DHIS2 configuration files. This directory will also be used for apps, files and log files. An example directory could be:



    sudo mkdir /var/www/dhis/config
1.4 Set ownership of the directory to ‘dhis_tl’ user created above



     sudo chown dhis_tl:dhis_tl /var/www/dhis/config 
Step-2. PostgreSQL installation
2.1 Install PostgreSQL by invoking:



    sudo apt-get update -y
    sudo apt-get install postgresql postgresql-contrib -y 
See detail: how to Install PostgreSQL on Ubuntu: https://tecadmin.net/install-postgresql-server-on-ubuntu

https://www.digitalocean.com/community/tutorials/how-to-install-postgresql-on-ubuntu-20-04-quickstart

2.2 Install Postgis:



    sudo apt-get install postgis -y
2.3 Create a non-privileged user called dhis_tl by invoking:

 

    sudo -u postgres createuser -SDRP dhis_tl 
Enter a secure password at the prompt. I set password ‘123456’. Note: To remember, I set the same username and password for the user and postgres.

2.4 Create a database by invoking:



     sudo -u postgres createdb -O dhis_tl dhis2 
2.5 The PostGIS extension is needed for several GIS/mapping features to work. DHIS2 will attempt to install the PostGIS extension during startup.



     sudo -u postgres psql -c "create extension postgis;" dhis2 
     sudo -u postgres psql -c "create extension pg_trgm;" dhis2 
Step-3: Database Configuration
3.1. The database connection information is provided to DHIS2 through a configuration file called dhis.conf. As an example this location could be:

 

    sudo -u dhis_tl nano /var/www/mydomain.com/config/dhis.conf 
A configuration file for PostgreSQL corresponding to the above setup has these properties:



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
The encryption.password property is the password used when encrypting and decrypting data in the database. Note that the password must not be changed once it has been set and data has been encrypted as the data can then no longer be decrypted. Remember to set a strong password of at least 24 characters.

Step-4: Java Installation
4.1 To install OpenJDK run below command



    sudo apt-get install openjdk-11-jdk -y
Note: The installation directory is /usr/lib/jvm/java-11-openjdk-amd64 which may change depending on the java version. Run below command to check the exact directory:



    ls /usr/lib/jvm
Step-5: Tomcat and DHIS2 Installation
5.1 Install tomcat 9

 sudo apt-get install tomcat9-user 
5.1 To create a Tomcat instance for DHIS2 move to the /var/www/mydomain.com folder created above:



     cd /var/www/dhis/ 
5.2 Create Tomcat instance:

 

    sudo tomcat9-instance-create tomcat-dhis 
5.3 Set ownership of the created folder to dhis_tl user

 

    sudo chown -R dhis_tl:dhis_tl /var/www/dhis/tomcat-dhis/ 
5.4 Edit setenv.sh:

 

    sudo nano /var/www/dhis/tomcat-dhis/bin/setenv.sh 
5.5 Replace all contents by following



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
Note: Please make sure the java installation directory matches the path given in JAVA_HOME above.

Step-6: DHIS2 download
6.1: The next step is to download the DHIS2 WAR file and place it into the webapps directory of Tomcat

Return to root:

 

    cd ~ 
Download:



     sudo wget https://s3-eu-west-1.amazonaws.com/releases.dhis2.org/2.37/dhis.war
6.2 Move the WAR file into the Tomcat webapps directory. We want to call the WAR file ROOT.war in order to make it available at localhost directly without a context path:



    sudo mv dhis.war /var/www/dhis/tomcat-dhis/webapps/ROOT.war
6.3 Replace everything in the file with the following lines:


`sudo nano /var/www/dhis/tomcat-dhis/bin/startup.sh `

    #!/bin/sh
    set -e
    
    if [ "$(id -u)" -eq "0" ]; then
       echo "This script must NOT be run as root" 1>&2
       exit 1
    fi
    
    export CATALINA_BASE="/var/www/dhis/tomcat-dhis"
    /usr/share/tomcat9/bin/startup.sh
    echo "Tomcat started"
Step-7: Running DHIS2
7.1 DHIS2 can now be started by invoking:



    sudo -u dhis_tl /var/www/dhis/tomcat-dhis/bin/startup.sh 
7.2 Warning: The DHIS2 server should never be run as root or other privileged user. DHIS2 can be stopped by invoking:



     sudo -u dhis_tl /var/www/dhis/tomcat-dhis/bin/shutdown.sh 
7.3 To monitor the behavior of Tomcat the log is the primary source of information. The log can be viewed with the following command:



    sudo tail -f /var/www/dhis/tomcat-dhis/logs/catalina.out 
7.4 Assuming that the WAR file is called ROOT.war, you can now access your DHIS2 instance at the following URL:


https://my-server-ip:8080/ 
Username: admin
Password: district
### Thank you
