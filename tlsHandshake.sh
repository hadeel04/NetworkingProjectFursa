#!/bin/bash

# Check if the server IP address is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <server-ip>"
    exit 1
fi

SERVER_IP=$1

# Step 1: Client Hello
echo "Step 1: Sending Client Hello..."
CLIENT_HELLO=$(curl -s -X POST -H "Content-Type: application/json" -d '{"version": "1.3", "ciphersSuites": ["TLS_AES_128_GCM_SHA256", "TLS_CHACHA20_POLY1305_SHA256"], "message": "Client Hello"}' http://$SERVER_IP:8080/clienthello)
if [ $? -ne 0 ]; then
    echo "Failed to send Client Hello"
    exit 2
fi

# Step 2: Server Hello
echo "Step 2: Received Server Hello..."
SERVER_HELLO=$(echo "$CLIENT_HELLO" | jq -r '.')
SESSION_ID=$(echo "$SERVER_HELLO" | jq -r '.sessionID')
SERVER_CERT=$(echo "$SERVER_HELLO" | jq -r '.serverCert')
echo "$SERVER_CERT" > server_cert.pem


# Step 3: Server Certificate Verification
echo "Step 3: Verifying Server Certificate..."
wget https://alonitac.github.io/DevOpsTheHardWay/networking_project/cert-ca-aws.pem
openssl verify -CAfile cert-ca-aws.pem cert.pem
if [ $? -ne 0 ]; then
    echo "Server Certificate is invalid."
    exit 5
fi


# Step 4: Client-Server master-key exchange
echo "Step 4: Generating and sending master key..."
MASTER_KEY=$(openssl rand -base64 32)
ENCRYPTED_MASTER_KEY=$(openssl smime -encrypt -aes-256-cbc -in <(echo "$MASTER_KEY") -outform DER server_cert.pem | base64 -w 0)


#Step 5: Server verification message
echo "Step 5: Sending master key and sample message..."
SAMPLE_MESSAGE="Hi server, please encrypt me and send to client!"
KEY_EXCHANGE=$(curl -s -X POST -H "Content-Type: application/json" -d "{\"sessionID\": \"$SESSION_ID\", \"masterKey\": \"$ENCRYPTED_MASTER_KEY\", \"sampleMessage\": \"$SAMPLE_MESSAGE\"}" http://$SERVER_IP:8080/keyexchange)
if [ $? -ne 0 ]; then
    echo "Failed to send master key and sample message"
    exit 3
fi


# Step 6: Server verification message
echo "Step 6: Verifying server's symmetric encryption..."
ENCRYPTED_SAMPLE_MESSAGE=$(echo "$KEY_EXCHANGE" | jq -r '.encryptedSampleMessage')
DECRYPTED_SAMPLE_MESSAGE=$(echo "$ENCRYPTED_SAMPLE_MESSAGE" | base64 -d | openssl enc -d -aes-256-cbc -pbkdf2 -k "$MASTER_KEY")
if [ "$DECRYPTED_SAMPLE_MESSAGE" != "$SAMPLE_MESSAGE" ]; then
    echo "Server symmetric encryption using the exchanged master-key has failed."
    exit 6
fi

echo "Client-Server TLS handshake has been completed successfully"