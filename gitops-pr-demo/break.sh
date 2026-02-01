#!/bin/bash

# Create a temporary directory
TEMP_DIR=$(mktemp -d)
echo "Created temporary directory: $TEMP_DIR"

# Clone the repository
git clone https://github.com/aaitaazizi/cloud-native-days-fr2026-kagent-demo.git "$TEMP_DIR"
cd "$TEMP_DIR/demo-app"

# Configure git user (required for commits)
git config user.email "breakit@example.com"
git config user.name "breakit"

# Make sure we're on main
git checkout main

# Modify the targetPort in the backend Service only
sed -i '' '/name: backend/,/^---/ s/targetPort: 9090/targetPort: 8080/' application.yaml

# Commit the changes to main
git add .
git commit -m "Breakit and change service targetport"

# Push main
git push origin main

# Clean up
cd - > /dev/null
rm -rf "$TEMP_DIR"
echo "Cleanup complete" 
