#!/bin/bash
# Script to setup a new AWS Lightsail server for production

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root or with sudo privileges"
  exit 1
fi

# Set variables
SERVER_IP=${1:-52.66.119.214}
PROJECT_DIR=${2:-/home/ubuntu/docker_django}

echo "Setting up server with IP: $SERVER_IP"
echo "Project will be installed in: $PROJECT_DIR"

# Update system
echo "Updating system packages..."
apt-get update && apt-get upgrade -y

# Install required packages
echo "Installing required packages..."
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    git \
    python3 \
    python3-pip \
    ufw

# Install Docker
if ! command -v docker &> /dev/null; then
    echo "Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    usermod -aG docker ubuntu
    systemctl enable docker
    systemctl start docker
    rm get-docker.sh
fi

# Install Docker Compose
if ! command -v docker-compose &> /dev/null; then
    echo "Installing Docker Compose..."
    curl -L "https://github.com/docker/compose/releases/download/v2.23.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
fi

# Configure firewall
echo "Configuring firewall..."
ufw allow ssh
ufw allow http
ufw allow https
ufw --force enable

# Create project directory
echo "Creating project directory..."
mkdir -p $PROJECT_DIR

# Clone project if git repository URL is provided
if [ ! -z "$3" ]; then
    echo "Cloning project repository..."
    git clone $3 $PROJECT_DIR
fi

# Copy scripts to project directory
if [ ! -d "$PROJECT_DIR/scripts" ]; then
    echo "Creating scripts directory..."
    mkdir -p $PROJECT_DIR/scripts
    
    # If we're running this script from the project
    if [ -f "/home/joel-thomas/Projects/docker_django/scripts/generate_ssl.sh" ]; then
        echo "Copying scripts from local project..."
        cp /home/joel-thomas/Projects/docker_django/scripts/generate_ssl.sh $PROJECT_DIR/scripts/
        cp /home/joel-thomas/Projects/docker_django/scripts/deploy_production.sh $PROJECT_DIR/scripts/
        chmod +x $PROJECT_DIR/scripts/*.sh
    fi
fi

# Create deploy.sh script in home directory for convenience
echo "Creating deploy.sh script in /home/ubuntu..."
cat > /home/ubuntu/deploy.sh << EOL
#!/bin/bash
cd $PROJECT_DIR
bash scripts/deploy_production.sh
EOL
chmod +x /home/ubuntu/deploy.sh
chown ubuntu:ubuntu /home/ubuntu/deploy.sh

# Create ssl.sh script in home directory for convenience
echo "Creating ssl.sh script in /home/ubuntu..."
cat > /home/ubuntu/ssl.sh << EOL
#!/bin/bash
cd $PROJECT_DIR
sudo bash scripts/generate_ssl.sh \$1 $SERVER_IP \$2
EOL
chmod +x /home/ubuntu/ssl.sh
chown ubuntu:ubuntu /home/ubuntu/ssl.sh

echo "Server setup completed successfully!"
echo "Run the following commands to deploy your application:"
echo "1. cd $PROJECT_DIR"
echo "2. ./scripts/generate_ssl.sh yourdomain.com $SERVER_IP admin@yourdomain.com  # For Let's Encrypt SSL"
echo "   OR"
echo "   ./scripts/generate_ssl.sh  # For self-signed SSL with IP: $SERVER_IP"
echo "3. ./scripts/deploy_production.sh"