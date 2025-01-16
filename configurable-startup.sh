#!/bin/bash

# Read the delay from the environment variable (default to 0 if not set)
DELAY=${DELAY:-1800}

if [ "$DELAY" -gt 0 ]; then
    echo -e "[DELAY] \033[32mDelay is set to $DELAY seconds. Bypassing traffic...\033[0m"
    
    while [ "$DELAY" -gt 0 ]; do
        # Convert delay to hh:mm:ss format
        HOURS=$((DELAY / 3600))
        MINUTES=$(((DELAY % 3600) / 60))
        SECONDS=$((DELAY % 60))
        
        echo "TEST"

        # Display the countdown timer
        printf "[DELAY] \033[32mTime remaining: %02d:%02d:%02d\033[0m" "$HOURS" "$MINUTES" "$SECONDS"
        
        # Wait for 5 seconds or the remaining time, whichever is smaller
        SLEEP_TIME=$((DELAY < 5 ? DELAY : 5))
        sleep "$SLEEP_TIME"
        
        # Decrease the delay
        DELAY=$((DELAY - SLEEP_TIME))
    done

    echo -e "[DELAY] \033[32mDelay completed. Proceeding with proxy.\033[0m"
else
    echo -e "[DELAY] \033[32mNo delay set. Proceeding with proxy.\033[0m"
fi

# Run the original Gluetun entrypoint or command
exec "$@"