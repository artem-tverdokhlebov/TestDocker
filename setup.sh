#!/bin/bash

# Stop existing containers
echo -e "\r\033[33mStopping existing Docker containers...\033[0m"
docker compose down

# Start the containers in detached mode
echo -e "\r\033[33mStarting Docker containers in detached mode...\033[0m"
DELAY=1000 docker compose up --build -d