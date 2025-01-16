#!/bin/bash

# Read the delay from the environment variable (default to 0 if not set)
DELAY=${DELAY:-1800}

if [ "$DELAY" -gt 0 ]; then
    echo -e "\r\nDelay is set to $DELAY seconds. Bypassing traffic..."
    
    while [ "$DELAY" -gt 0 ]; do
        # Convert delay to hh:mm:ss format
        HOURS=$((DELAY / 3600))
        MINUTES=$(((DELAY % 3600) / 60))
        SECONDS=$((DELAY % 60))
        
        # Display the countdown timer
        printf "\r\n[DELAY] \033[32mTime remaining: %02d:%02d:%02d\033[0m" "$HOURS" "$MINUTES" "$SECONDS"
        
        # Wait for 1 second
        sleep 1
        
        # Decrease the delay
        DELAY=$((DELAY - 1))
    done

    echo -e "\r\n[DELAY] Delay completed. Proceeding with proxy."
else
    echo -e "\r\n[DELAY] No delay set. Proceeding with proxy."
fi

# Run the original Gluetun entrypoint or command
exec "$@"