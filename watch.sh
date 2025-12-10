#!/bin/bash
# Trap Ctrl+C and exit cleanly
trap 'exit 0' INT

# Check if entr is installed
if ! command -v entr &> /dev/null
then
    echo "Error: 'entr' is not installed."
    echo "Please install 'entr' to use the watch mode."
    echo "  On macOS: brew install entr"
    echo "  On Linux (Debian/Ubuntu): sudo apt-get install entr"
    echo "  On Linux (Fedora): sudo dnf install entr"
    exit 1
fi

while true; do
    find . -name "*.pu" | entr -p make
    # A brief pause to prevent busy-looping if entr exits immediately
    sleep 0.1
done
