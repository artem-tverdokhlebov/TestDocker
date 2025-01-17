#!/bin/bash

# Stop existing containers
docker compose -p osxvm down

# Start the containers in detached mode
echo -e "\r\033[33mStarting Docker containers in detached mode...\033[0m"
DELAY=0 docker compose -p osxvm up