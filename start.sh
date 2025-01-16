#!/bin/bash

# Function to clean up background processes and Docker containers
cleanup() {
    echo "Cleaning up..."
    if [[ -n "$LOGS_PID" ]]; then
        echo "Stopping log viewer..."
        kill "$LOGS_PID" 2>/dev/null
    fi
    echo "Stopping Docker container..."
    sudo docker compose -p macos_project down
    echo "Cleanup complete. Exiting."
    exit 0
}

# Trap Ctrl+C (SIGINT) and call the cleanup function
trap cleanup SIGINT

# Stop and remove existing containers
sudo docker compose -p macos_project down

# Remove unused Docker objects
sudo docker system prune -f

# Start and rebuild the container
sudo docker compose -p macos_project up --build -d

# Start a background process to follow the container logs
echo "Starting to follow logs for gluetun and macos-13 container..."
sudo docker logs gluetun macos-13 -f &
LOGS_PID=$!

VNC_PORT=5999
VNC_HOST=localhost

printf "\nChecking if VNC server is fully operational on $VNC_HOST:$VNC_PORT..."

while true; do
    # Try connecting to the VNC server and read the response
    RESPONSE=$(echo | timeout 2 nc $VNC_HOST $VNC_PORT 2>/dev/null)

    # Check if the response contains the expected VNC handshake (RFB protocol)
    if [[ $RESPONSE =~ ^RFB ]]; then
        printf "\nVNC server is fully operational! Handshake response: $RESPONSE"
        break
    else
        printf "\nVNC server not ready yet. Retrying in 30 seconds..."
        sleep 30
    fi
done

printf "\nVNC server is ready. Launching VNC viewer..."
vncviewer $VNC_HOST:$VNC_PORT &

# Wait for vncviewer to close
VNCVIEWER_PID=$!
wait $VNCVIEWER_PID

# Clean up after VNC viewer is closed
cleanup