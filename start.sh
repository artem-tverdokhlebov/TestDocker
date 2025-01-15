#!/bin/bash

# Stop and remove existing containers
sudo docker compose -p macos_project down

# Remove unused Docker objects
sudo docker system prune -f

# Start and rebuild the container
sudo docker compose -p macos_project up --build