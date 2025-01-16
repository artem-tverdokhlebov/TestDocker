#!/bin/bash

# Function to clean up background processes and Docker containers
cleanup() {
    echo -e "\r[START] \033[33mCleaning up...\033[0m"

    # Stop the VNC viewer if it is running
    if [[ -n "$VNCVIEWER_PID" ]]; then
        echo -e "\r[START] \033[33mStopping VNC viewer...\033[0m"
        kill "$VNCVIEWER_PID" 2>/dev/null || true
    fi

    # Stop the log viewers if they are running
    if [[ -n "$LOGS1_PID" ]]; then
        echo -e "\r[START] \033[33mStopping log viewer for gluetun...\033[0m"
        kill "$LOGS1_PID" 2>/dev/null || true
    fi

    echo -e "\r[START] \033[33mStopping Docker container...\033[0m"
    sudo docker compose -p macos_project down
    echo -e "\r[START] \033[33mCleanup complete. Exiting.\033[0m"

    # Reset the terminal to its default state
    tput cnorm  # Show the cursor
    stty echo   # Re-enable input echo
    
    exit 0
}

# Trap Ctrl+C (SIGINT) and call the cleanup function
trap cleanup SIGINT SIGTERM SIGHUP

# Stop and remove existing containers
sudo docker compose -p macos_project down

# Start the containers in detached mode
echo -e "\r[START] Starting Docker containers in detached mode..."
sudo docker compose -p macos_project up --build -d

# Wait for gluetun container to become healthy
echo -e "\r[START] Waiting for gluetun container to become healthy..."
while true; do
    STATUS=$(sudo docker inspect -f '{{.State.Health.Status}}' gluetun 2>/dev/null)
    if [[ "$STATUS" == "healthy" ]]; then
        echo -e "\r[START] \033[33mGluetun container is healthy and ready.\033[0m"

        # Check current OpenVPN status
        CURRENT_STATUS=$(curl -s http://localhost:8000/v1/openvpn/status | jq -r .status)
        echo -e "\r[START] \033[33mCurrent OpenVPN status: $CURRENT_STATUS\033[0m"

        # Retrieve the current public IP address
        PUBLIC_IP=$(curl -s http://localhost:8000/v1/publicip/ip | jq -r .ip)
        echo -e "\r[START] \033[33mPublic IP before stopping OpenVPN: $PUBLIC_IP\033[0m"

        # Temporarily stop OpenVPN
        echo -e "\r[START] \033[33mStopping OpenVPN...\033[0m"
        curl -X PUT -H "Content-Type: application/json" \
             -d '{"status":"stopped"}' \
             http://localhost:8000/v1/openvpn/status
        
        # Wait for 3 seconds
        sleep 3

        # Retrieve the current public IP address
        PUBLIC_IP=$(curl -s http://localhost:8000/v1/publicip/ip | jq -r .ip)
        echo -e "\r[START] \033[33mPublic IP after stopping OpenVPN: $PUBLIC_IP\033[0m"

        # Start OpenVPN again
        echo -e "\r[START] \033[33mStarting OpenVPN...\033[0m"
        curl -X PUT -H "Content-Type: application/json" \
             -d '{"status":"running"}' \
             http://localhost:8000/v1/openvpn/status

        break
    else
        echo -e "\r[START] \033[33mGluetun container not ready yet. Retrying in 5 seconds...\033[0m"
        sleep 5
    fi
done

# Start a background process to follow the container logs
echo -e "\r[START] Starting to follow logs for gluetun container..."
sudo docker logs gluetun -f &
LOGS1_PID=$!

VNC_PORT=5999
VNC_HOST=localhost

echo -e "\r[START] \033[33mChecking if VNC server is fully operational on $VNC_HOST:$VNC_PORT...\033[0m"

while true; do
    # Try connecting to the VNC server and read the response
    RESPONSE=$(echo | timeout 2 nc $VNC_HOST $VNC_PORT 2>/dev/null)

    # Check if the response contains the expected VNC handshake (RFB protocol)
    if [[ $RESPONSE =~ ^RFB ]]; then
        echo -e "\r[START] \033[33mVNC server is fully operational! Handshake response: $RESPONSE\033[0m"
        break
    else
        echo -e "\r[START] \033[33mVNC server not ready yet. Retrying in 30 seconds...\033[0m"
        sleep 30
    fi
done

MAX_RETRIES=10
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    echo -e "\r[START] \033[33mVNC server is ready. Launching VNC viewer (attempt $((RETRY_COUNT + 1)) of $MAX_RETRIES)...\033[0m"
    vncviewer $VNC_HOST:$VNC_PORT &
    VNCVIEWER_PID=$!

    # Monitor the VNC viewer process
    while kill -0 $VNCVIEWER_PID 2>/dev/null; do
        sleep 1
    done

    # Check exit status of the VNC viewer process
    wait $VNCVIEWER_PID
    EXIT_STATUS=$?

    # if [ $EXIT_STATUS -eq 0 ]; then
    #     echo -e "\033[32mVNC viewer exited successfully. Exiting script.\033[0m"
    #     exit 0
    # else
        echo -e "\033[31mVNC viewer process ended unexpectedly. Retrying...\033[0m"
        ((RETRY_COUNT++))
    # fi

    # Add a delay between retries
    sleep 5
done

# Clean up after VNC viewer is closed
cleanup