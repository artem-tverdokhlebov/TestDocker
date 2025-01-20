#!/bin/bash

# Stop existing containers
echo -e "\r\033[33mStopping existing Docker containers...\033[0m"
docker compose -p osxvm down

# Start the containers in detached mode
echo -e "\r\033[33mStarting Docker containers in detached mode...\033[0m"
docker compose -p osxvm up