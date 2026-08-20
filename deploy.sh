#!/bin/bash

set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "================================="
echo "Deploying Alpha Q7"
echo "Project: $PROJECT_DIR"
echo "================================="

echo "Updating frontend..."

sudo mkdir -p /var/www/alpha-q7
sudo cp -r "$PROJECT_DIR/frontend/public/." /var/www/alpha-q7/

sudo chown -R www-data:www-data /var/www/alpha-q7
sudo chmod -R 755 /var/www/alpha-q7

echo "Installing backend dependencies..."

cd "$PROJECT_DIR/backend/server"

npm install

echo "Starting or restarting backend..."

cd "$PROJECT_DIR/backend/server/src"

if pm2 describe alpha-q7-backend > /dev/null 2>&1; then
    echo "Backend already exists. Restarting..."
    pm2 restart alpha-q7-backend
else
    echo "Backend not found. Starting new PM2 process..."
    pm2 start server.js --name alpha-q7-backend
fi

echo "Checking Nginx..."

sudo nginx -t
sudo systemctl reload nginx

echo "================================="
echo "Deployment completed successfully!"
echo "================================="
