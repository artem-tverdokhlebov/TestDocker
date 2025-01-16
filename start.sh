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
    RESPONSE=$(echo | timeout 2 nc $VNC_HOST $VNC_PORT 2>/dev/null)

    # Check if the response contains the expected VNC handshake (RFB protocol)
    if [[ $RESPONSE =~ ^RFB ]]; then
        echo "VNC server is fully operational! Handshake response: $RESPONSE"
        break
    else
        echo "VNC server not ready yet. Retrying in 5 seconds..."
        sleep 5
    fi
done

# Start a background process to follow the container logs
echo "Starting to follow logs for macos-13 container..."
sudo docker logs macos-13 -f &
LOGS_PID=$!

echo "VNC server is ready. Launching VNC viewer..."
vncviewer $VNC_HOST:$VNC_PORT &

# Wait for vncviewer to close
VNCVIEWER_PID=$!
wait $VNCVIEWER_PID

# Stop the log-following process when VNC viewer closes
echo "Stopping log viewer..."
kill $LOGS_PID

echo "VNC viewer closed. Stopping Docker container..."

# Stop and remove containers after VNC viewer is closed
sudo docker compose -p macos_project down

echo "Docker containers stopped. Exiting script."