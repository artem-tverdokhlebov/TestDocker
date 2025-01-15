#!/bin/bash

sudo docker compose -p macos_project down

sudo docker system prune -f

xhost +

sudo docker compose -p macos_project up --build