#!/bin/bash

# Hostinger Auto-Deploy Script
# This script runs after git pull on Hostinger servers

echo "🚀 Starting deployment..."

# Set permissions for web files
find . -type f -name "*.html" -exec chmod 644 {} \;
find . -type f -name "*.css" -exec chmod 644 {} \;
find . -type f -name "*.js" -exec chmod 644 {} \;
find . -type f -name "*.png" -exec chmod 644 {} \;
find . -type f -name "*.jpg" -exec chmod 644 {} \;
find . -type f -name "*.svg" -exec chmod 644 {} \;
find . -type d -exec chmod 755 {} \;

# Set proper permissions for .htaccess
if [ -f "Webpage/.htaccess" ]; then
    chmod 644 Webpage/.htaccess
    echo "✅ .htaccess permissions set"
fi

# Copy files from Webpage directory to web root if needed
# (Hostinger might deploy to root, this ensures proper structure)
if [ -d "Webpage" ] && [ "$(pwd)" != "/public_html" ]; then
    echo "📁 Copying files from Webpage directory..."
    cp -r Webpage/* ./
    echo "✅ Files copied to web root"
fi

# Clear any cache (if applicable)
echo "🧹 Clearing cache..."

# Set proper file ownership (if needed on some Hostinger plans)
# chown -R $(whoami):$(whoami) .

echo "✅ Deployment completed successfully!"
echo "🌐 Your website should be live at your domain"

# Optional: Send notification (you can add webhook calls here)
# curl -X POST "YOUR_SLACK_WEBHOOK" -d '{"text":"Website deployed successfully!"}' 