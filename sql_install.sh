#!/bin/bash

# Load settings configuration file
. ./setting.config

# Use the following variables to control your install:

# Password for the SA user (required)
MSSQL_SA_PASSWORD="$sa_password"

# Product ID of the version of SQL server you're installing
# Must be evaluation, developer, express, web, standard, enterprise, or your 25 digit product key
# Defaults to developer
MSSQL_PID="$sql_version"

# Install SQL Server Agent (recommended)
SQL_INSTALL_AGENT="$agent_install"

# Install SQL Server Full Text Search (optional)
 SQL_INSTALL_FULLTEXT="$fulltext_install"

# Create an additional user with sysadmin privileges (optional)
 USER_INSTALL="$user_install"
 SQL_INSTALL_USER_NAME="$install_username"
 SQL_INSTALL_USER_PASSWORD="$install_password"

# Sets the linux verison
LINUX_VERSION=$(lsb_release -sr)
echo "$LINUX_VERSION"

echo ""
echo ""
echo "MSSQL_SA_PASSWORD: $MSSQL_SA_PASSWORD"
echo "MSSQL_PID: $MSSQL_PID"
echo "SQL_INSTALL_AGENT: $SQL_INSTALL_AGENT"
echo "SQL_INSTALL_FULLTEXT: $SQL_INSTALL_FULLTEXT"
echo "USER_INSTALL: $USER_INSTALL"
echo "SQL_INSTALL_USER_NAME: $SQL_INSTALL_USER_NAME"
echo "SQL_INSTALL_USER_PASSWORD: $SQL_INSTALL_USER_PASSWORD"
echo ""
echo ""

# Get repository signing key
echo "Getting repository signing key...."
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add - 

# Add required repositories
echo "Adding SQL Server repository...."
sql_repo="$(wget -qO- https://packages.microsoft.com/config/ubuntu/$LINUX_VERSION/mssql-server-2019.list)"
sudo add-apt-repository "${sql_repo}"
other_repo="$(wget -qO- https://packages.microsoft.com/config/ubuntu/$LINUX_VERSION/prod.list)"
sudo add-apt-repository "${other_repo}"

echo "Updating repository list...."
sudo apt-get update 

# Add MSSql Server packages to system
echo "Adding SQL Server packages..."
sudo apt-get install -y mssql-server mssql-server-ha

# Do initial sql server setup
#  the sa password and product id must be set
echo "Running mssql-conf setup..."
    sudo MSSQL_SA_PASSWORD=$MSSQL_SA_PASSWORD \
        MSSQL_PID=$MSSQL_PID \
        /opt/mssql/bin/mssql-conf -n setup accept-eula


#  Install sql server tools and te linux ODBC drivers
echo "Installing mssql-tools and unixODBC developer..."
sudo ACCEPT_EULA=Y apt-get install -y mssql-tools unixodbc-dev


# Add SQL Server tools to the path by default:
echo "Adding SQL Server tools to your path..."
echo PATH="$PATH:/opt/mssql-tools/bin" >> ~/.bash_profile
echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bashrc
source ~/.bashrc

# Optional SQL Server Agent installation:
if [ ! -z $SQL_INSTALL_AGENT ] &&  [ $SQL_INSTALL_AGENT == "y" ]
then
  echo Installing SQL Server Agent...
  sudo /opt/mssql/bin/mssql-conf set sqlagent.enabled true 
  sudo systemctl restart mssql-server
fi

# Optional SQL Server Full Text Search installation:
if [ ! -z $SQL_INSTALL_FULLTEXT ] &&  [ $SQL_INSTALL_FULLTEXTufw == "y" ]
then
    echo Installing SQL Server Full-Text Search...
    sudo apt-get install -y mssql-server-fts
fi

# Configure firewall to allow TCP port 1433:
echo Configuring UFW to allow traffic on port 1433...
sudo ufw allow 1433/tcp
sudo ufw reload

# Optional example of post-installation configuration.
# Trace flags 1204 and 1222 are for deadlock tracing.
# echo Setting trace flags...
# sudo /opt/mssql/bin/mssql-conf traceflag 1204 1222 on

# Restart SQL Server after installing:
echo Restarting SQL Server...
sudo systemctl restart mssql-server

# Connect to server and get the version:
counter=1
errstatus=1
while [ $counter -le 5 ] && [ $errstatus = 1 ]
do
  echo Waiting for SQL Server to start...
  sleep 3s
  /opt/mssql-tools/bin/sqlcmd \
    -S localhost \
    -U SA \
    -P $MSSQL_SA_PASSWORD \
    -Q "SELECT @@VERSION" 2>/dev/null
  errstatus=$?
  ((counter++))
done

# Display error if connection failed:
if [ $errstatus = 1 ]
then
  echo Cannot connect to SQL Server, installation aborted
  exit $errstatus
fi

# Optional new user creation:
echo "Checking if user should be created..."
if [ $USER_INSTALL == "y" ] && [ ! -z $SQL_INSTALL_USER_NAME ] && [ ! -z $SQL_INSTALL_USER_PASSWORD ]
then
  echo Creating user $SQL_INSTALL_USER_NAME
  /opt/mssql-tools/bin/sqlcmd \
    -S localhost \
    -U SA \
    -P $MSSQL_SA_PASSWORD \
    -Q "CREATE LOGIN [$SQL_INSTALL_USER_NAME] WITH PASSWORD=N'$SQL_INSTALL_USER_PASSWORD', DEFAULT_DATABASE=[master], CHECK_EXPIRATION=ON, CHECK_POLICY=ON; ALTER SERVER ROLE [sysadmin] ADD MEMBER [$SQL_INSTALL_USER_NAME]"
else
  echo "Checking if user should be created..."
  echo " USER_INSTALL $USER_INSTALL"    
  echo " SQL_INSTALL_USER_NAME $SQL_INSTALL_USER_NAME"    
  echo " SQL_INSTALL_USER_PASSWORD $SQL_INSTALL_USER_PASSWORD"    
fi

# Enable hadr on Sql Server
echo "Enabling hadr..."
sudo /opt/mssql/bin/mssql-conf set hadr.hadrenabled 1   
sudo systemctl restart mssql-server

echo Done!