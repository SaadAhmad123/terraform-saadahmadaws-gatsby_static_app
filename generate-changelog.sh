#!/bin/bash

# Function to get user input
get_input() {
    read -p "$1: " value
    echo "$value"
}

# Get version number
version=$(get_input "Enter the version number (e.g., 1.0.0)")

# Get change details
echo "Enter the details of the change (press Ctrl+D when finished):"
change_details=$(cat)

# Get current date
current_date=$(date +"%Y-%m-%d")

# Prepare the changelog entry
changelog_entry="## [$version] - $current_date

$change_details

"

# Check if CHANGELOG.md exists
if [ -f "CHANGELOG.md" ]; then
    # File exists, prepend the new entry
    temp_file=$(mktemp)
    echo "$changelog_entry" > "$temp_file"
    cat "CHANGELOG.md" >> "$temp_file"
    mv "$temp_file" "CHANGELOG.md"
    echo "CHANGELOG.md updated successfully."
else
    # File doesn't exist, create it with the new entry
    echo "# Changelog

All notable changes to this project will be documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

$changelog_entry" > "CHANGELOG.md"
    echo "CHANGELOG.md created successfully."
fi