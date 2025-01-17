#!/bin/bash

# Function to clean up background processes and Docker containers
cleanup() {
    echo -e "\r\033[33mCleaning up...\033[0m"

    echo -e "\r\033[33mStopping Docker container...\033[0m"
    sudo docker compose -p osxvm down
    echo -e "\r\033[33mCleanup complete. Exiting.\033[0m"

    exit 0
}

# Trap Ctrl+C (SIGINT) and call the cleanup function
trap cleanup SIGINT SIGTERM SIGHUP

# Stop and remove existing containers
sudo docker compose -p osxvm down

# Start the containers in detached mode
echo -e "\r\033[33mStarting Docker containers in detached mode...\033[0m"
DELAY=0 sudo docker compose -p osxvm up 

# Clean up after VNC viewer is closed
cleanup