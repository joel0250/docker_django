# Docker Django Project Template - Production Environment

This guide covers the setup and usage of the production environment for the Docker Django project template, specifically for deployment to AWS Lightsail with IP 52.66.119.214.

## Overview

The production environment is configured for secure, high-performance deployment:
- HTTPS with SSL/TLS
- HTTP to HTTPS redirection
- Gunicorn WSGI server for Django
- PostgreSQL database
- Redis for caching and session storage
- Nginx as a reverse proxy with optimized settings
- Enhanced security headers
- Sentry for error monitoring (optional)

## Directory Structure

```
docker_django/
├── docker/
│   └── production/
│       ├── Dockerfile             # Django application container configuration
│       ├── docker-compose.yml     # Services definition for production environment
│       ├── .env.production        # Environment variables
│       └── nginx/
│           ├── Dockerfile         # Nginx container configuration
│           ├── nginx.conf         # Nginx server configuration
│           └── ssl/               # SSL certificates
│               ├── certificate.crt
│               └── private.key
├── django_app/
│   ├── manage.py                  # Django management script
│   ├── project_name/              # Django project
│   │   ├── settings/
│   │   │   ├── base.py            # Base settings shared across environments
│   │   │   └── production.py      # Production environment specific settings
│   │   ├── urls.py                # URL routing
│   │   └── wsgi.py                # WSGI application
│   ├── apps/                      # Django applications
│   ├── static/                    # Static files
│   ├── media/                     # User-uploaded files
│   └── requirements/              # Python dependencies
│       ├── base.txt               # Base requirements
│       └── production.txt         # Production environment requirements
└── scripts/
    ├── deploy_production.sh       # Deployment automation script
    ├── generate_ssl.sh            # SSL certificate generation script
    └── server_setup.sh            # Server setup automation script
```

## TL;DR: Deploying to AWS Lightsail (IP: 52.66.119.214)

1. SSH into your server:
   ```bash
   ssh ubuntu@52.66.119.214
   ```

2. Clone your project repository:
   ```bash
   git clone https://your-repository-url.git ~/docker_django
   cd ~/docker_django
   ```

3. Run the server setup script:
   ```bash
   sudo bash scripts/server_setup.sh
   ```

4. Generate SSL certificates:
   ```bash
   sudo ./ssl.sh
   ```

5. Deploy the application:
   ```bash
   ./deploy.sh
   ```

The application will be available at:
- HTTPS: https://52.66.119.214
- HTTP: http://52.66.119.214 (redirects to HTTPS)

## Detailed Deployment Guide

### Step 1: Server Setup

The `server_setup.sh` script prepares the AWS Lightsail instance with all necessary dependencies and configurations:

```bash
sudo bash scripts/server_setup.sh 52.66.119.214
```

This script will:
- Update system packages
- Install Docker and Docker Compose
- Configure firewall rules (opening ports 22, 80, and 443)
- Create convenience scripts in the home directory

### Step 2: SSL Certificate Generation

For production deployment with HTTPS, you need SSL certificates. You have two options:

#### Option A: Domain-based SSL with Let's Encrypt

If you have a domain pointed to your server:

```bash
sudo ./ssl.sh yourdomain.com admin@yourdomain.com
```

This will:
- Use Certbot to obtain a free SSL certificate from Let's Encrypt
- Set up automatic renewal
- Configure Nginx to use the certificate

#### Option B: IP-based SSL with Self-Signed Certificate

If you're accessing the server directly via IP (52.66.119.214):

```bash
sudo ./ssl.sh
```

This will:
- Generate a self-signed certificate for your IP address
- Configure Nginx to use the certificate
- Note: Browsers will show a security warning, but the connection will be encrypted

### Step 3: Application Deployment

The `deploy_production.sh` script automates the deployment process:

```bash
./deploy.sh
```

This script will:
1. Pull the latest changes from the git repository (if available)
2. Build and start all Docker containers
3. Run database migrations
4. Collect static files
5. Create a superuser if one doesn't exist

### Step 4: Post-Deployment Configuration

After deploying, you should:

1. Change the default superuser password:
   ```bash
   docker-compose -f docker/production/docker-compose.yml exec web python manage.py changepassword admin
   ```

2. Verify that all services are running:
   ```bash
   docker-compose -f docker/production/docker-compose.yml ps
   ```

3. Check the application logs:
   ```bash
   docker-compose -f docker/production/docker-compose.yml logs -f web
   ```

## Configuration

### Environment Variables

The production environment uses the `.env.production` file in the `docker/production/` directory. Key variables include:

```
DEBUG=False
SECRET_KEY=production-secret-key-change-this
DJANGO_SETTINGS_MODULE=project_name.settings.production
ALLOWED_HOSTS=52.66.119.214,example.com,www.example.com,localhost,127.0.0.1
POSTGRES_DB=db_production
POSTGRES_USER=postgres_user
POSTGRES_PASSWORD=postgres_password_secure
SENTRY_DSN=your-sentry-dsn  # Optional
```

### Django Settings

Production-specific Django settings are defined in `django_app/project_name/settings/production.py`. This file extends the base settings and adds production-specific configurations, including:

- Debug mode disabled
- Strict security settings (HTTPS, secure cookies, HSTS)
- Whitenoise for static file serving
- Redis for caching and session storage
- Comprehensive logging configuration

### Nginx Configuration

The Nginx configuration is defined in `docker/production/nginx/nginx.conf`. It's configured to:

- Redirect HTTP to HTTPS
- Serve the application over HTTPS
- Optimize SSL/TLS settings
- Add security headers
- Serve static and media files with caching
- Provide a health check endpoint

## Maintenance Tasks

### Database Backups

Create a database backup:

```bash
docker-compose -f docker/production/docker-compose.yml exec db pg_dump -U postgres_user db_production > backup_$(date +%Y%m%d).sql
```

### Viewing Logs

View application logs:

```bash
docker-compose -f docker/production/docker-compose.yml logs -f web
```

View Nginx logs:

```bash
docker-compose -f docker/production/docker-compose.yml logs -f nginx
```

### Updating the Application

To update the application with the latest code:

```bash
cd ~/docker_django
git pull
./deploy.sh
```

### SSL Certificate Renewal

If you're using Let's Encrypt certificates, they expire after 90 days. The certificate renewal is handled automatically by cron, but you can manually renew with:

```bash
sudo certbot renew
```

Then update the certificates in the project:

```bash
sudo ./ssl.sh yourdomain.com
```

## Security Best Practices

The production environment is configured with the following security measures:

1. **HTTPS Only**: All HTTP traffic is redirected to HTTPS
2. **Secure Headers**: Strict security headers are set in Nginx
3. **Secure Cookies**: Session and CSRF cookies are set to secure
4. **HSTS**: HTTP Strict Transport Security is enabled
5. **XSS Protection**: Cross-site scripting protection is enabled
6. **Content Security Policy**: Restrictive CSP is configured
7. **Database Security**: Strong passwords and limited access

Additional recommendations:

- Change all default passwords
- Regularly update dependencies
- Enable backups for your database
- Monitor logs for unusual activity
- Implement rate limiting for login attempts

## Troubleshooting

### Common Issues

1. **SSL Certificate Errors**:
   - Check that certificate files exist and have correct permissions
   - For Let's Encrypt, verify that the domain points to your server
   - For self-signed certificates, accept the browser warning

2. **502 Bad Gateway**:
   - Check if the Django application is running: `docker-compose logs web`
   - Verify Nginx can connect to the web service

3. **Database Connection Issues**:
   - Verify database credentials in `.env.production`
   - Check if the database container is running: `docker-compose ps`

4. **Static Files Not Loading**:
   - Ensure you've run `collectstatic`
   - Check that Nginx configuration correctly maps to static file locations

### Useful Diagnostic Commands

```bash
# Check container status
docker-compose -f docker/production/docker-compose.yml ps

# Check service logs
docker-compose -f docker/production/docker-compose.yml logs -f web

# Check if web service can connect to the database
docker-compose -f docker/production/docker-compose.yml exec web python -c "import django; django.setup(); from django.db import connection; connection.ensure_connection()"

# Check Nginx configuration
docker-compose -f docker/production/docker-compose.yml exec nginx nginx -t
```

## Scaling and Performance

### Increasing Worker Processes

To increase the number of Gunicorn workers:

1. Edit `docker/production/Dockerfile` and modify the CMD at the end to include more workers:
   ```
   CMD ["gunicorn", "project_name.wsgi:application", "--bind", "0.0.0.0:8000", "--workers", "6", "--timeout", "120"]
   ```

2. Rebuild and restart the web service:
   ```bash
   docker-compose -f docker/production/docker-compose.yml build web
   docker-compose -f docker/production/docker-compose.yml up -d
   ```

### Monitoring Performance

To monitor performance:

1. Check resource usage:
   ```bash
   docker stats
   ```

2. Check application response time:
   ```bash
   time curl -s https://52.66.119.214/health/
   ```

## Transitioning Between Environments

- [README_LOCAL.md](README_LOCAL.md) - For the local development environment
- [README_STAGING.md](README_STAGING.md) - For the staging environment