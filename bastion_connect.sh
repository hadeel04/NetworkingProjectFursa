#!/bin/bash

# Check if KEY_PATH environment variable exists
if [ -z "${KEY_PATH}" ]; then
    echo "KEY_PATH env var is expected"
    exit 5
fi

# Check if at least one argument is provided
if [ "$#" -eq 0 ]; then
    echo "Please provide bastion IP address"
    exit 5
fi

# Assign the first argument to the bastion_ip
bastion_ip=$1


# Check if the second argument exists
if [ "$#" -gt 1 ]; then
    private_ip=$2

    # Check if the third argument exists
    if [ "$#" -gt 2 ]; then
        command=$3
        ssh  -o "StrictHostKeyChecking=no" -A -i "${KEY_PATH}" ubuntu@"${bastion_ip}" ssh -i key.pem ubuntu@"${private_ip}" "${command}"
    else
        ssh -t -o "StrictHostKeyChecking=no" -A -i "${KEY_PATH}" ubuntu@"${bastion_ip}" ssh -t -o "StrictHostKeyChecking=no" -i key.pem ubuntu@"${private_ip}"
    fi
else
    ssh -t -o "StrictHostKeyChecking=no" -i "${KEY_PATH}" ubuntu@"${bastion_ip}"
fi