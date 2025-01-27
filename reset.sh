#!/bin/bash

# Stop existing containers
echo -e "\r\033[33mStopping existing Docker containers...\033[0m"
docker compose down

# Remove data directory contents
echo -e "\r\033[31mRemoving data directory contents...\033[0m"
rm -rf data/*