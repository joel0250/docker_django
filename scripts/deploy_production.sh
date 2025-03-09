#!/bin/bash
# Script to deploy the application to production

# Change to the project directory
cd /home/joel-thomas/Projects/docker_django

# Variables
ENVIRONMENT=${1:-production}
DOCKER_DIR="docker/$ENVIRONMENT"

# Pull latest changes if in a git repository
if [ -d .git ]; then
    echo "Pulling latest changes from git repository..."
    git pull
fi

# Build and start the containers
echo "Building and starting the $ENVIRONMENT environment..."
docker-compose -f $DOCKER_DIR/docker-compose.yml down
docker-compose -f $DOCKER_DIR/docker-compose.yml build
docker-compose -f $DOCKER_DIR/docker-compose.yml up -d

# Wait for the database to be ready
echo "Waiting for database to be ready..."
sleep 10

# Run migrations
echo "Running database migrations..."
docker-compose -f $DOCKER_DIR/docker-compose.yml exec web python manage.py migrate

# Collect static files
echo "Collecting static files..."
docker-compose -f $DOCKER_DIR/docker-compose.yml exec web python manage.py collectstatic --noinput

# Create superuser if not exists
echo "Checking if superuser exists..."
docker-compose -f $DOCKER_DIR/docker-compose.yml exec web python -c "
from django.contrib.auth.models import User
if not User.objects.filter(username='admin').exists():
    print('Creating superuser...')
    User.objects.create_superuser('admin', 'admin@example.com', 'admin123')
    print('Superuser created successfully.')
else:
    print('Superuser already exists.')
"

echo "$ENVIRONMENT deployment completed successfully!"
echo "You can access the application at:"
if [ "$ENVIRONMENT" == "production" ]; then
    echo "- HTTPS: https://52.66.119.214"
    echo "- HTTP (redirected to HTTPS): http://52.66.119.214"
elif [ "$ENVIRONMENT" == "staging" ]; then
    echo "- HTTP: http://staging.mydomain.com"
else
    echo "- Local: http://localhost:8000"
fi