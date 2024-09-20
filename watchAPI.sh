#!/bin/bash

# Default update interval in seconds
UPDATE_INTERVAL=60

# Function to display usage information
usage() {
    echo "Usage: $0 [interval]"
    echo "  interval: Update interval in seconds (default: 60)"
    exit 1
}

# Check if an argument is provided and if it's a positive integer
if [ $# -eq 1 ]; then
    if [[ $1 =~ ^[0-9]+$ ]] && [ $1 -gt 0 ]; then
        UPDATE_INTERVAL=$1
    else
        echo "Error: Interval must be a positive integer."
        usage
    fi
elif [ $# -gt 1 ]; then
    echo "Error: Too many arguments."
    usage
fi

# Function to check if jq is installed
has_jq() {
    command -v jq >/dev/null 2>&1
}

# Function to format JSON output
format_json() {
    local endpoint=$1
    local json=$2
    
    echo "=== $endpoint ==="
    if has_jq; then
        echo "$json" | jq -r 'to_entries | .[] | "\(.key): \(.value)"' | sed 's/^/  /'
    else
        echo "$json" | sed 's/[{},]/\n/g' | sed 's/^ *//; s/ *$//' | sed '/^$/d' | sed 's/^/  /'
    fi
    echo
}

# Function to format skills data
format_skills() {
    local json=$1
    echo "=== /skills ==="
    if has_jq; then
        echo "$json" | jq -r '.[] | "  Skill: \(."Skill name")\n  Level: \(.Level)\n  Boosted level: \(."Boosted level")\n  Boosted amount: \(."Boosted amount")\n  Current XP: \(."Current XP")\n"'
    else
        echo "$json" | sed 's/\[{/\n/g; s/},{/\n/g; s/}]/\n/g' | sed 's/^"//; s/"://g; s/"//g' | sed 's/,/\n  /g' | sed 's/^/  /'
    fi
    echo
}

# Function to fetch and format data from an endpoint
fetch_and_format() {
    local endpoint=$1
    local url="http://localhost:8081$endpoint"
    local data=$(curl -s "$url")
    format_json "$endpoint" "$data"
}

echo "Monitoring endpoints with update interval of $UPDATE_INTERVAL seconds. Press Ctrl+C to stop."

# Main loop
while true; do
    clear
    
    # Skills data (special formatting)
    skills_data=$(curl -s "http://localhost:8081/skills")
    format_skills "$skills_data"
    
    fetch_and_format "/skills"
    # Other endpoints
    fetch_and_format "/accountinfo"
    fetch_and_format "/events"
    fetch_and_format "/quests"
    fetch_and_format "/inventory"
    fetch_and_format "/equipment"
    fetch_and_format "/bank"
    fetch_and_format "/combat"

    # Wait for the specified interval before the next update
    sleep $UPDATE_INTERVAL
done