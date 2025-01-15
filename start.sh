#!/bin/bash

# Stop and remove existing containers
sudo docker compose -p macos_project down

# Remove unused Docker objects
sudo docker system prune -f

# Start and rebuild the container
sudo docker compose -p macos_project up --build -d

# Wait for the VNC port to be available
VNC_PORT=5999
echo "Waiting for VNC server to be ready on localhost:$VNC_PORT..."
while ! nc -z localhost $VNC_PORT; do
    sleep 1
done
echo "VNC server is now ready!"

# Launch VNC viewer
vncviewer localhost:$VNC_PORT