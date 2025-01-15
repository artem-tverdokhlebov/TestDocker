#!/bin/bash

# Stop and remove existing containers
sudo docker compose -p macos_project down

# Remove unused Docker objects
sudo docker system prune -f

# Start and rebuild the container
sudo docker compose -p macos_project up --build -d

VNC_PORT=5999
VNC_HOST=localhost

echo "Checking if VNC server is fully operational on $VNC_HOST:$VNC_PORT..."

while true; do
    # Try connecting to the VNC server and read the response
    RESPONSE=$(echo -n | nc $VNC_HOST $VNC_PORT)

    # Check if the response contains the expected VNC handshake (RFB protocol)
    if [[ $RESPONSE == RFB* ]]; then
        echo "VNC server is fully operational! Handshake response: $RESPONSE"
        break
    else
        echo "VNC server not ready yet. Retrying in 1 second..."
        sleep 1
    fi
done

echo "VNC server is ready. Launching VNC viewer..."
vncviewer $VNC_HOST:$VNC_PORT