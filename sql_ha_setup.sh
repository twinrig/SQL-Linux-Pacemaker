#!/bin/bash

# Load settings configuration file
. ./setting.config

# Enable hadr on Sql Server
echo "Enabling hadr..."
sudo /opt/mssql/bin/mssql-conf set hadr.hadrenabled 1   
sudo systemctl restart mssql-server