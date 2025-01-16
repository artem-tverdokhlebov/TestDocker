#!/bin/bash

# Read the delay from the environment variable (default to 0 if not set)
DELAY=${DELAY:-1800}

if [ "$DELAY" -gt 0 ]; then
    echo "Delay is set to $DELAY seconds. Skipping health checks and bypassing VPN traffic..."

    # Sleep for the specified delay duration
    sleep "$DELAY"
else
    echo "No delay set. Proceeding with normal startup and health checks."
fi

# Run the original Gluetun entrypoint or command
exec "$@"