#!/bin/bash
# Trap Ctrl+C and exit cleanly
trap 'exit 0' INT

while true; do
    find . -name "*.pu" | entr -p make
    # A brief pause to prevent busy-looping if entr exits immediately
    sleep 0.1
done