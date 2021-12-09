#! /bin/bash


. ./setting.config

echo "$sa_password"

# Install SQL Server Agent (recommended)
SQL_INSTALL_AGENT="$sa_password"


echo "$SQL_INSTALL_AGENT"
# Optional SQL Server Agent installation:
if [ ! -z $SQL_INSTALL_AGENT ] &&  [ $SQL_INSTALL_AGENT == "y" ]
then
  echo Installing SQL Server Agent...
  echo $SQL_INSTALL_AGENT
  fi