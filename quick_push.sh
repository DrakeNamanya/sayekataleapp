#!/bin/bash

# Quick Push to GitHub Script
# Usage: ./quick_push.sh YOUR_GITHUB_TOKEN

if [ -z "$1" ]; then
    echo "❌ Error: GitHub token required"
    echo ""
    echo "Usage: ./quick_push.sh YOUR_GITHUB_TOKEN"
    echo ""
    echo "Get your token from: https://github.com/settings/tokens"
    echo ""
    exit 1
fi

TOKEN=$1
REPO="github.com/DrakeNamanya/sayekataleapp.git"

echo "🚀 Pushing to GitHub..."
echo ""

cd /home/user/flutter_app

# Configure git to use token
git remote set-url origin https://$TOKEN@$REPO

# Push to main
git push origin main

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Successfully pushed to GitHub!"
    echo ""
    echo "🔗 View your repo: https://github.com/DrakeNamanya/sayekataleapp"
    echo ""
else
    echo ""
    echo "❌ Push failed. Please check:"
    echo "  1. Token is valid and has 'repo' scope"
    echo "  2. You have push access to the repository"
    echo "  3. Repository exists and is accessible"
    echo ""
fi
