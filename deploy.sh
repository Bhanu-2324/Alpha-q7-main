#!/bin/bash

set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "================================="
echo "Deploying Alpha Q7"
echo "Project: $PROJECT_DIR"
echo "================================="

# -------------------------------
# FRONTEND DEPLOYMENT
# -------------------------------

echo "Updating frontend..."

sudo mkdir -p /var/www/alpha-q7

sudo cp -r "$PROJECT_DIR/frontend/public/." /var/www/alpha-q7/

sudo chown -R www-data:www-data /var/www/alpha-q7
sudo chmod -R 755 /var/www/alpha-q7


# -------------------------------
# BACKEND DEPLOYMENT
# -------------------------------

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


# -------------------------------
# NGINX CONFIGURATION
# -------------------------------

echo "Configuring Nginx..."

sudo tee /etc/nginx/sites-available/alpha-q7 > /dev/null <<'EOF'
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    server_name _;

    root /var/www/alpha-q7;
    index index.html;

    location /api/ {
        proxy_pass http://127.0.0.1:4000;
        proxy_http_version 1.1;

        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location / {
        try_files $uri $uri/ =404;
    }
}
EOF

sudo rm -f /etc/nginx/sites-enabled/default

sudo ln -sf /etc/nginx/sites-available/alpha-q7 \
/etc/nginx/sites-enabled/alpha-q7


# -------------------------------
# TEST AND RELOAD NGINX
# -------------------------------

echo "Checking Nginx..."

sudo nginx -t
sudo systemctl enable nginx
sudo systemctl restart nginx


echo "Saving PM2 startup configuration..."

pm2 save


echo "================================="
echo "Deployment completed successfully!"
echo "================================="
