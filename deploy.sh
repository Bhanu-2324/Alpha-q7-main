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

echo "Restarting backend..."

pm2 restart alpha-q7-backend || pm2 restart alpha-backend

echo "Checking Nginx..."

sudo nginx -t
sudo systemctl reload nginx

echo "================================="
echo "Deployment completed successfully!"
echo "================================="
