#!/bin/bash

# Check if the private instance IP is provided
if [ -z "$1" ]; then
   echo "Usage: $0 <private-instance-ip>"
   exit 1
fi

private_instance_ip=$1

# Create temporary copy of the existing private key and set permissions
if [ -f ~/key.pem ]; then
   mv  key.pem  old_key.pem
fi


if [ -f ~/key.pem.pub ]; then
    mv  key.pem.pub  old_key.pem.pub
fi

# Generate a new SSH key pair (private key: key.pem, public key: key.pem.pub)
ssh-keygen -t rsa -b 4096 -f ~/key.pem -N ""


# Copy the public key to the private instance
cat key.pem.pub | ssh -i old_key.pem ubuntu@$private_instance_ip "cat > ~/.ssh/authorized_keys"










