#!/bin/bash

sudo docker compose -p macos_project down

sudo docker system prune -f

sudo docker compose -p macos_project up --build

xhost +