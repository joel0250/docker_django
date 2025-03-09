# Docker Django Project Template - Staging Environment

This guide covers the setup and usage of the staging environment for the Docker Django project template.

## Overview

The staging environment is designed to mirror the production environment while providing easier testing and debugging capabilities:
- HTTP only (no HTTPS)
- Gunicorn WSGI server for Django
- PostgreSQL database
- Whitenoise for static file serving
- Nginx as a reverse proxy
- Moderate security settings

## Directory Structure

```
docker_django/
├── docker/
│   └── staging/
│       ├── Dockerfile             # Django application container configuration
│       ├── docker-compose.yml     # Services definition for staging environment
│       ├── .env.staging           # Environment variables
│       └── nginx/
│           ├── Dockerfile         # Nginx container configuration
│           └── nginx.conf         # Nginx server configuration
└── django_app/
    ├── manage.py                  # Django management script
    ├── project_name/              # Django project
    │   ├── settings/
    │   │   ├── base.py            # Base settings shared across environments
    │   │   └── staging.py         # Staging environment specific settings
    │   ├── urls.py                # URL routing
    │   └── wsgi.py                # WSGI application
    ├── apps/                      # Django applications
    ├── static/                    # Static files
    ├── media/                     # User-uploaded files
    └── requirements/              # Python dependencies
        ├── base.txt               # Base requirements
        └── staging.txt            # Staging environment requirements
```

## Quick Start

### Prerequisites

- Docker and Docker Compose installed on your machine
- Git (optional, for version control)

### Starting the Staging Environment

1. Clone the repository (if not already done):
   ```bash
   git clone <repository-url>
   cd docker_django
   ```

2. Start all services:
   ```bash
   cd docker/staging
   docker-compose up -d
   ```

3. Run initial database migrations:
   ```bash
   docker-compose exec web python manage.py migrate
   ```

4. Create a superuser for the admin interface:
   ```bash
   docker-compose exec web python manage.py createsuperuser
   ```

5. Collect static files:
   ```bash
   docker-compose exec web python manage.py collectstatic --noinput
   ```

6. Access the application at:
   - Main application: http://localhost:8080 (via Nginx) or http://localhost:8001 (direct)
   - Admin panel: http://localhost:8080/admin/

### Stopping the Environment

```bash
cd docker/staging
docker-compose down
```

To remove all data volumes (database data, etc.):
```bash
docker-compose down -v
```

## Configuration

### Environment Variables

The staging environment uses the `.env.staging` file in the `docker/staging/` directory. Key variables include:

```
DEBUG=False
SECRET_KEY=staging-secret-key-change-this
DJANGO_SETTINGS_MODULE=project_name.settings.staging
ALLOWED_HOSTS=staging.mydomain.com,localhost,127.0.0.1
POSTGRES_DB=db_staging
POSTGRES_USER=postgres_user
POSTGRES_PASSWORD=postgres_password_staging
```

### Django Settings

Staging-specific Django settings are defined in `django_app/project_name/settings/staging.py`. This file extends the base settings and adds staging-specific configurations, including:

- Debug mode disabled
- Whitenoise for static file serving
- Moderate security settings
- Allowed hosts configured for the staging domain

### Nginx Configuration

The Nginx configuration is defined in `docker/staging/nginx/nginx.conf`. It's configured to:

- Serve the application on port 80
- Proxy requests to the Django application
- Serve static and media files
- Add basic security headers

## Common Tasks

### Running Management Commands

Execute Django management commands through Docker Compose:

```bash
docker-compose exec web python manage.py <command>
```

Examples:
```bash
# Make migrations
docker-compose exec web python manage.py makemigrations

# Apply migrations
docker-compose exec web python manage.py migrate

# Create superuser
docker-compose exec web python manage.py createsuperuser

# Collect static files
docker-compose exec web python manage.py collectstatic --noinput

# Run Django shell
docker-compose exec web python manage.py shell
```

### Viewing Logs

View logs from all services:
```bash
docker-compose logs -f
```

View logs from a specific service:
```bash
docker-compose logs -f web
docker-compose logs -f db
docker-compose logs -f nginx
```

### Accessing the Database

The PostgreSQL database is accessible at:
- Host: localhost
- Port: 5434 (mapped from container port 5432)
- Database: db_staging
- Username: postgres_user
- Password: postgres_password_staging

You can connect using any PostgreSQL client, or use the psql command-line tool through Docker:
```bash
docker-compose exec db psql -U postgres_user -d db_staging
```

## Deployment to a Remote Staging Server

To deploy the staging environment to a remote server:

1. Clone the repository on the server:
   ```bash
   git clone <repository-url> ~/docker_django
   cd ~/docker_django
   ```

2. Configure the domain in the appropriate files:
   - Update `ALLOWED_HOSTS` in `.env.staging` or `django_app/project_name/settings/staging.py`
   - Update `server_name` in `docker/staging/nginx/nginx.conf`

3. Start the services:
   ```bash
   cd docker/staging
   docker-compose up -d
   ```

4. Run migrations and collect static files:
   ```bash
   docker-compose exec web python manage.py migrate
   docker-compose exec web python manage.py collectstatic --noinput
   ```

5. Create a superuser:
   ```bash
   docker-compose exec web python manage.py createsuperuser
   ```

## Differences from Production

The staging environment differs from production in the following ways:

1. **HTTP Only**: No HTTPS configuration to simplify testing
2. **Simplified Security**: Some security measures are relaxed
3. **Domain Configuration**: Uses the staging domain instead of the production domain
4. **Resource Allocation**: Generally uses fewer resources (workers, etc.)

## Troubleshooting

### Common Issues

1. **502 Bad Gateway**: If Nginx returns a 502 error, it may not be able to connect to the Django application. Check if the web service is running with `docker-compose ps` and check logs with `docker-compose logs web`.

2. **Static Files Not Loading**: If static files are not being served correctly, ensure that you've run `collectstatic` and that the Nginx configuration correctly maps to static file locations.

3. **Database Connection Issues**: Verify that the database credentials in `.env.staging` match what's expected in the Django settings.

### Useful Diagnostic Commands

```bash
# Check container status
docker-compose ps

# Check if web service can connect to the database
docker-compose exec web python -c "import django; django.setup(); from django.db import connection; connection.ensure_connection()"

# Check Nginx configuration
docker-compose exec nginx nginx -t
```

## Transitioning Between Environments

- [README_LOCAL.md](README_LOCAL.md) - For the local development environment
- [README_PRODUCTION.md](README_PRODUCTION.md) - For the production environment