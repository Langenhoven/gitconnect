#!/bin/bash

# GitHub Credential Helper Script
# This script helps with automatically authenticating to GitHub

# Check if the script is being run with arguments
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <github-Username> <github-token>"
    echo ""
    echo "Arguments:"
    echo "  github-Username (Not email): Your GitHub login (Username)"
    echo "  github-token: Your GitHub personal access token (classic)"
    echo ""
    echo "Note: You can create a personal access token at https://github.com/settings/tokens"
    exit 1
fi

# Assign command line arguments to variables
GITHUB_USERNAME="$1"
GITHUB_TOKEN="$2"

# Configure Git to use the credential helper
git config --global credential.helper store

# Create the Git credentials file if it doesn't exist
CREDENTIALS_FILE="$HOME/.git-credentials"
touch "$CREDENTIALS_FILE"
chmod 600 "$CREDENTIALS_FILE" # Set secure permissions

# Check if credentials already exist for github.com
if grep -q "https://" "$CREDENTIALS_FILE"; then
    echo "GitHub credentials already exist in $CREDENTIALS_FILE"
    echo "username=$GITHUB_USERNAME"
    echo "Do you want to update them? (y/n)"
    read -r response
    if [[ "$response" != "y" ]]; then
        echo "Operation cancelled.Stored Credentials will continue to be used"
        exit 0
    fi
    # Remove existing GitHub credentials
    sed -i '/https:\/\/.*@github.com/d' "$CREDENTIALS_FILE"
fi

# Add credentials using git credential approve
echo "protocol=https
host=github.com
username=$GITHUB_USERNAME
password=$GITHUB_TOKEN" | git credential approve

echo "GitHub credentials have been successfully stored!"
echo "You can now use git push and pull without entering credentials."

# Verify the configuration
echo ""
echo "Verifying Git configuration:"
echo "- Credential Helper: $(git config --global credential.helper)"
echo "- Credentials File: $CREDENTIALS_FILE exists: $(test -f "$CREDENTIALS_FILE" && echo "Yes" || echo "No")"

# Test the connection if the user wants to
echo ""
echo "Do you want to test the connection to GitHub? (y/n)"
read -r test_connection
if [[ "$test_connection" == "y" ]]; then
    echo "Testing SSH connection to GitHub..."
    if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
        echo "SSH authentication successful!"
    else
        echo "Testing HTTPS authentication..."
        # Test using the GitHub API instead of a specific repository
        if curl -s -u "$GITHUB_USERNAME:$GITHUB_TOKEN" https://api.github.com/user | grep -q "login"; then
            echo "HTTPS authentication successful!"
        else
            echo "HTTPS authentication failed. Please check your credentials."
        fi
    fi
fi

echo ""
echo "Setup complete!"
echo "You can now use git push and pull without entering credentials."
echo ""
