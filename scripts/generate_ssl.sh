#!/bin/bash
# Script to generate SSL certificates for production environment

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root or with sudo privileges"
  exit 1
fi

# Get the project directory (where this script is located)
PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"

# Set variables
DOMAIN=${1:-52.66.119.214}
SERVER_IP=${2:-52.66.119.214}
EMAIL=${3:-admin@example.com}
CERT_DIR="$PROJECT_DIR/docker/production/nginx/ssl"

# Make sure directory exists
mkdir -p $CERT_DIR

# Check if certbot is installed
if ! command -v certbot &> /dev/null; then
    echo "Certbot is not installed. Installing..."
    apt-get update
    apt-get install -y certbot
    echo "Certbot installed."
fi

# Check which method to use
if [[ "$DOMAIN" == "example.com" || "$DOMAIN" == "localhost" || "$DOMAIN" == "52.66.119.214"]]; then
    echo "Generating self-signed certificate for local development..."
    echo $DOMAIN;
    
    # Generate self-signed certificate
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout $CERT_DIR/private.key \
        -out $CERT_DIR/certificate.crt \
        -subj "/C=US/ST=State/L=City/O=Organization/CN=$DOMAIN" \
        -addext "subjectAltName = DNS:$DOMAIN, DNS:www.$DOMAIN, IP:$SERVER_IP, DNS:localhost"
    
    echo "Self-signed certificate generated successfully!"
    echo "Certificate saved to $CERT_DIR/certificate.crt"
    echo "Private key saved to $CERT_DIR/private.key"

else
    echo "Generating Let's Encrypt certificate for $DOMAIN..."
    
    # Stop any running nginx
    if pgrep nginx > /dev/null; then
        echo "Temporarily stopping nginx..."
        systemctl stop nginx
    fi
    
    # Get certificate from Let's Encrypt
    certbot certonly --standalone \
        --preferred-challenges http \
        --agree-tos \
        --non-interactive \
        --domain $DOMAIN \
        --domain www.$DOMAIN \
        --email $EMAIL
    
    # Copy certificates to the project directory
    echo "Copying certificates to project directory..."
    cp /etc/letsencrypt/live/$DOMAIN/fullchain.pem $CERT_DIR/certificate.crt
    cp /etc/letsencrypt/live/$DOMAIN/privkey.pem $CERT_DIR/private.key
    
    # Restart nginx if it was running
    if pgrep nginx > /dev/null; then
        echo "Restarting nginx..."
        systemctl start nginx
    fi
    
    echo "Let's Encrypt certificate generated successfully!"
    echo "Certificate saved to $CERT_DIR/certificate.crt"
    echo "Private key saved to $CERT_DIR/private.key"
    
    # Setup auto-renewal
    echo "Setting up auto-renewal..."
    echo "0 0,12 * * * root python -c 'import random; import time; time.sleep(random.random() * 3600)' && certbot renew -q && cp /etc/letsencrypt/live/$DOMAIN/fullchain.pem $CERT_DIR/certificate.crt && cp /etc/letsencrypt/live/$DOMAIN/privkey.pem $CERT_DIR/private.key" | sudo tee -a /etc/crontab > /dev/null
    echo "Auto-renewal setup complete."
fi