#!/bin/bash

# Function to clean up background processes and Docker containers
cleanup() {
    echo -e "\r\033[33mCleaning up...\033[0m"

    # Stop the VNC viewer if it is running
    if [[ -n "$VNCVIEWER_PID" ]]; then
        echo -e "\r\033[33mStopping VNC viewer...\033[0m"
        kill "$VNCVIEWER_PID" 2>/dev/null || true
    fi

    echo -e "\r\033[33mStopping Docker container...\033[0m"
    sudo docker compose -p macos_project down
    echo -e "\r\033[33mCleanup complete. Exiting.\033[0m"

    # Reset the terminal to its default state
    tput cnorm # Show the cursor
    stty echo # Re-enable input echo
    
    exit 0
}

# Trap Ctrl+C (SIGINT) and call the cleanup function
trap cleanup SIGINT SIGTERM SIGHUP

# Stop and remove existing containers
sudo docker compose -p osxvm down

# Start the containers in detached mode
echo -e "\r\033[33mStarting Docker containers in detached mode...\033[0m"
DELAY=0 sudo docker compose -p osxvm up -d

VNC_PORT=5999
VNC_HOST=localhost

echo -e "\r\033[33mChecking if VNC server is fully operational on $VNC_HOST:$VNC_PORT...\033[0m"

while true; do
    # Try connecting to the VNC server and read the response
    RESPONSE=$(echo | timeout 2 nc $VNC_HOST $VNC_PORT 2>/dev/null)

    # Check if the response contains the expected VNC handshake (RFB protocol)
    if [[ $RESPONSE =~ ^RFB ]]; then
        echo -e "\r\033[33mVNC server is fully operational! Handshake response: $RESPONSE\033[0m"
        break
    else
        echo -e "\r\033[33mVNC server not ready yet. Retrying in 30 seconds...\033[0m"
        sleep 30
    fi
done

echo -e "\r\033[33mVNC server is ready. Launching VNC viewer...\033[0m"
vncviewer $VNC_HOST:$VNC_PORT &
VNCVIEWER_PID=$!

# Monitor the VNC viewer process
while kill -0 $VNCVIEWER_PID 2>/dev/null; do
    sleep 1
done

# Clean up after VNC viewer is closed
cleanup