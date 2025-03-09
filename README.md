# Docker Django Project Template

This is a complete project template for deploying Django applications using Docker with support for local, staging, and production environments. The project includes automation scripts for deployment and SSL certificate management, specifically designed to work with AWS Lightsail.

## Environment-Specific Documentation

This project has separate README files for each environment:

- [Local Development Environment](README_LOCAL.md) - For development on your local machine
- [Staging Environment](README_STAGING.md) - For testing in a production-like environment
- [Production Environment](README_PRODUCTION.md) - For deploying to AWS Lightsail (IP: 52.66.119.214)

## Project Structure

```
docker_django/
├── docker/
│   ├── local/
│   │   ├── Dockerfile
│   │   ├── docker-compose.yml
│   │   ├── .env.local
│   │   └── nginx/
│   │       ├── Dockerfile
│   │       └── nginx.conf
│   ├── staging/
│   │   ├── Dockerfile
│   │   ├── docker-compose.yml
│   │   ├── .env.staging
│   │   └── nginx/
│   │       ├── Dockerfile
│   │       └── nginx.conf
│   └── production/
│       ├── Dockerfile
│       ├── docker-compose.yml
│       ├── .env.production
│       └── nginx/
│           ├── Dockerfile
│           ├── nginx.conf
│           └── ssl/
│               ├── certificate.crt
│               └── private.key
├── django_app/
│   ├── manage.py
│   ├── project_name/
│   │   ├── __init__.py
│   │   ├── asgi.py
│   │   ├── celery.py
│   │   ├── urls.py
│   │   ├── wsgi.py
│   │   └── settings/
│   │       ├── __init__.py
│   │       ├── base.py
│   │       ├── local.py
│   │       ├── staging.py
│   │       └── production.py
│   └── requirements/
│       ├── base.txt
│       ├── local.txt
│       ├── staging.txt
│       └── production.txt
└── scripts/
    ├── deploy_production.sh
    ├── generate_ssl.sh
    └── server_setup.sh
```

# Quick Start Guide

## 1. Local Development Environment

The local environment is designed for development purposes with:
- Debug mode enabled
- Hot-reloading with Django runserver
- PostgreSQL database
- Nginx reverse proxy

### Running the Local Environment

```bash
# Start all services
cd docker/local
docker-compose up -d

# Apply migrations
docker-compose exec web python manage.py migrate

# Create superuser
docker-compose exec web python manage.py createsuperuser
```

### Accessing the Local Environment

- **Main application**: http://localhost:80 (via Nginx) or http://localhost:8000 (direct)
- **Admin panel**: http://localhost/admin/
- **Database**: PostgreSQL on port 5432 (mapped to 5433 on host)

## 2. Staging Environment

The staging environment mimics production but with simplified configuration:
- HTTP only (no HTTPS)
- Whitenoise for static file serving
- Moderate security settings 

### Running the Staging Environment

```bash
cd docker/staging
docker-compose up -d
```

### Accessing the Staging Environment

- **Main application**: http://localhost:8080 (via Nginx) or http://localhost:8001 (direct)
- **Admin panel**: http://localhost:8080/admin/
- **Database**: PostgreSQL on port 5432 (mapped to 5434 on host)

## 3. Production Environment

The production environment is configured for secure, high-performance deployment:
- HTTPS with SSL/TLS
- HTTP to HTTPS redirection
- Production-ready security headers
- Redis caching and session storage
- Sentry error monitoring

### Running the Production Environment

```bash
cd docker/production
docker-compose up -d
```

### Accessing the Production Environment (Local Testing)

- **HTTPS**: https://localhost:8443 (will show certificate warning)
- **HTTP**: http://localhost:80 (redirects to HTTPS)
- **Direct Django access**: http://localhost:8002
- **Database**: PostgreSQL on port 5432 (mapped to 5435 on host)

# Deploying to AWS Lightsail (IP: 52.66.119.214)

This project includes scripts for easy deployment to AWS Lightsail. Follow these steps to deploy to your production server.

## Step 1: Set Up the AWS Lightsail Server

1. Connect to your AWS Lightsail instance with SSH:

   ```bash
   ssh ubuntu@52.66.119.214
   ```

2. Clone the repository on the server:

   ```bash
   git clone https://your-repository-url.git ~/docker_django
   ```

3. Run the server setup script:

   ```bash
   cd ~/docker_django
   sudo bash scripts/server_setup.sh 52.66.119.214
   ```

   This script will:
   - Update system packages
   - Install Docker and Docker Compose
   - Configure firewall rules
   - Set up convenience scripts in the home directory

## Step 2: Generate SSL Certificates

For production deployment, you have two options:

### Option A: Use Let's Encrypt for a Registered Domain

If you have a domain pointed to your server:

```bash
sudo ./ssl.sh yourdomain.com admin@yourdomain.com
```

### Option B: Use Self-Signed Certificates for IP-Only Access

If you're accessing directly via IP address (52.66.119.214):

```bash
sudo ./ssl.sh
```

This will create self-signed certificates configured for your IP address. Browsers will show a security warning, but the connection will be encrypted.

## Step 3: Deploy the Application

Run the deployment script to build and start all services:

```bash
./deploy.sh
```

This will:
1. Pull the latest changes (if using git)
2. Build and start the Docker containers
3. Run database migrations
4. Collect static files
5. Create a superuser if one doesn't exist

## Step 4: Access Your Production Application

Your application is now accessible at:

- **HTTPS**: https://52.66.119.214
- **HTTP**: http://52.66.119.214 (redirects to HTTPS)

The admin panel can be accessed at:
- https://52.66.119.214/admin/

Default superuser credentials:
- Username: admin
- Password: admin123

**Important**: Change the default superuser password immediately!

```bash
docker-compose -f docker/production/docker-compose.yml exec web python manage.py changepassword admin
```

# Maintenance Tasks

## Database Backups

Create a database backup:

```bash
docker-compose -f docker/production/docker-compose.yml exec db pg_dump -U postgres_user db_production > backup_$(date +%Y%m%d).sql
```

## Logs

View application logs:

```bash
docker-compose -f docker/production/docker-compose.yml logs -f web
```

View Nginx logs:

```bash
docker-compose -f docker/production/docker-compose.yml logs -f nginx
```

## Updating the Application

Pull the latest changes and redeploy:

```bash
cd ~/docker_django
git pull
./deploy.sh
```

## SSL Certificate Renewal

Let's Encrypt certificates are valid for 90 days. The certificate renewal is handled automatically by cron, but you can manually renew with:

```bash
sudo certbot renew
```

Then update the certificates in the project:

```bash
sudo ./ssl.sh yourdomain.com
```

# Environment-Specific Configuration

Each environment has its own configuration:

## Local Environment (.env.local)

```
DEBUG=True
SECRET_KEY=local-development-secret-key
DJANGO_SETTINGS_MODULE=project_name.settings.local
POSTGRES_DB=db_local
POSTGRES_USER=postgres_user
POSTGRES_PASSWORD=postgres_password
```

## Staging Environment (.env.staging)

```
DEBUG=False
SECRET_KEY=staging-secret-key
DJANGO_SETTINGS_MODULE=project_name.settings.staging
ALLOWED_HOSTS=staging.mydomain.com,localhost,127.0.0.1
POSTGRES_DB=db_staging
POSTGRES_USER=postgres_user
POSTGRES_PASSWORD=postgres_password_staging
```

## Production Environment (.env.production)

```
DEBUG=False
SECRET_KEY=production-secret-key
DJANGO_SETTINGS_MODULE=project_name.settings.production
ALLOWED_HOSTS=52.66.119.214,example.com,www.example.com,localhost,127.0.0.1
POSTGRES_DB=db_production
POSTGRES_USER=postgres_user
POSTGRES_PASSWORD=postgres_password_secure
```

# Customizing the Project

1. Rename the project:
   - Replace all occurrences of "project_name" with your actual project name

2. Add your Django apps:
   - Create your apps in the django_app/apps directory
   - Add them to INSTALLED_APPS in settings/base.py

3. Configure environment-specific variables:
   - Update .env files with appropriate values for each environment

4. Update production domain/IP:
   - Update ALLOWED_HOSTS in production settings
   - Update server_name in Nginx configuration
   - Update SSL certificate configuration

# Security Recommendations

- Change all default passwords and credentials
- Store sensitive values in environment variables, not in code
- Regularly update dependencies and base images
- Enable backups for your database
- Monitor logs for unusual activity
- Use strong passwords for database and admin users
- Keep SSL certificates up to date
- Implement rate limiting for login attempts

# Troubleshooting

## Common Issues

1. **Nginx returns a 502 Bad Gateway error:**
   - Check if the Django application is running: `docker-compose logs web`
   - Verify Nginx can connect to the web service

2. **Static files are not loading:**
   - Run `docker-compose exec web python manage.py collectstatic`
   - Check if volumes are mapped correctly in docker-compose.yml

3. **Database connection error:**
   - Verify database credentials in .env file
   - Check if the database container is running: `docker-compose ps`

4. **SSL certificate errors:**
   - Ensure certificate files exist in the correct location
   - Verify file permissions allow Nginx to read the certificates

5. **Permission denied errors:**
   - Ensure the current user is in the docker group: `sudo usermod -aG docker $USER`

For more detailed troubleshooting, check the container logs:
```bash
docker-compose logs -f [service_name]
```

# Additional Resources

- [Django Documentation](https://docs.djangoproject.com/)
- [Docker Documentation](https://docs.docker.com/)
- [Nginx Documentation](https://nginx.org/en/docs/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Let's Encrypt Documentation](https://letsencrypt.org/docs/)
- [AWS Lightsail Documentation](https://lightsail.aws.amazon.com/ls/docs/en_us/all)