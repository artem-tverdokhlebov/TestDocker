#!/bin/bash

# Validate DELAY
DELAY=${DELAY:-1800}

if ! [[ "$DELAY" =~ ^[0-9]+$ ]]; then
    echo -e "\r[ERROR] \033[31mDELAY must be a non-negative integer. Exiting.\033[0m"
    exit 1
fi

if [ "$DELAY" -gt 0 ]; then
    echo -e "\r[DELAY] \033[32mDelay is set to $DELAY seconds. Bypassing traffic...\033[0m"
    
    while [ "$DELAY" -gt 0 ]; do
        # Convert delay to hh:mm:ss format
        HOURS=$((DELAY / 3600))
        MINUTES=$(((DELAY % 3600) / 60))
        SECONDS=$((DELAY % 60))

        # Display the countdown timer
        echo -e "\r[DELAY] \033[32mTime remaining: $DELAY s\033[0m"

        # Wait for 5 seconds or the remaining time, whichever is smaller
        SLEEP_TIME=$((DELAY < 5 ? DELAY : 5))
        sleep "$SLEEP_TIME"

        # Decrease the delay
        DELAY=$((DELAY - SLEEP_TIME))
    done

    echo -e "\r[DELAY] \033[32mDelay completed. Proceeding with proxy.\033[0m"
else
    echo -e "\r[DELAY] \033[32mNo delay set. Proceeding with proxy.\033[0m"
fi

# Run the original Gluetun entrypoint or command
exec "$@"