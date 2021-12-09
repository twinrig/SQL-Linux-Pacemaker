#!/bin/bash

clear

. ./setting.config
# Add pacemaker and required packages to system
echo "Adding Pacemaker packages..."
sudo apt-get -y install pacemaker pcs fence-agents resource-agents

# Set the password for the hacluster user
echo "Setting hacluster password..."
echo "hacluster:$hacluster_password" | sudo chpasswd

# Enable pacemaker service (pcsd)
echo "Enabling pcsd service..."
sudo systemctl enable pcsd
sudo systemctl start pcsd


# Validte pcsd service is running
counter=1
errstatus=1
while [ $counter -le 5 ] && [ $errstatus = 1 ]
do
  echo Waiting for pcsd to start...
  sleep 3s
  systemctl is-active --quiet pcsd.service
  errstatus=$?
  ((counter++))
done

# Display error and exit if the service is down
if [ $errstatus = 1 ]
then
  echo "pcsd service has not started"
  echo ""
  echo "Exiting....."
  exit $errstatus
else
  echo ""
  echo "pcsd service has started"
fi

####################
# Setup new cluser #
####################

echo ""
echo ""
echo ""
echo "**************************************************************************"
echo "**************************************************************************"
echo "Creating New Cluser"
echo "**************************************************************************"
echo "**************************************************************************"
echo ""
echo ""
echo ""


# Destroy any existing clusters
echo ""
echo ""
echo "Destroying any existing clusters..."
sudo pcs cluster destroy


# Authorize the nodes
sudo pcs cluster auth $node1 $node2 $node3 -u hacluster

# Create the cluster
sudo pcs cluster setup --name $clu_name $node1 $node2 $node3 --start --all --enable
