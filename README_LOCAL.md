# Docker Django Project Template - Local Environment

This guide covers the setup and usage of the local development environment for the Docker Django project template.

## Overview

The local environment is designed for development purposes with:
- Debug mode enabled
- Hot-reloading with Django's runserver
- PostgreSQL database
- Nginx reverse proxy for static files
- Direct access to the Django application

## Directory Structure

```
docker_django/
├── docker/
│   └── local/
│       ├── Dockerfile             # Django application container configuration
│       ├── docker-compose.yml     # Services definition for local environment
│       ├── .env.local             # Environment variables
│       └── nginx/
│           ├── Dockerfile         # Nginx container configuration
│           └── nginx.conf         # Nginx server configuration
└── django_app/
    ├── manage.py                  # Django management script
    ├── project_name/              # Django project
    │   ├── settings/
    │   │   ├── base.py            # Base settings shared across environments
    │   │   └── local.py           # Local environment specific settings
    │   ├── urls.py                # URL routing
    │   └── wsgi.py                # WSGI application
    ├── apps/                      # Django applications
    ├── static/                    # Static files
    ├── media/                     # User-uploaded files
    └── requirements/              # Python dependencies
        ├── base.txt               # Base requirements
        └── local.txt              # Local environment requirements
```

## Quick Start

### Prerequisites

- Docker and Docker Compose installed on your machine
- Git (optional, for version control)

### Starting the Local Environment

1. Clone the repository (if not already done):
   ```bash
   git clone <repository-url>
   cd docker_django
   ```

2. Start all services:
   ```bash
   cd docker/local
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

5. Access the application at:
   - Main application: http://localhost:80 (via Nginx) or http://localhost:8000 (direct)
   - Admin panel: http://localhost/admin/

### Stopping the Environment

```bash
cd docker/local
docker-compose down
```

To remove all data volumes (database data, etc.):
```bash
docker-compose down -v
```

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
- Port: 5433 (mapped from container port 5432)
- Database: db_local
- Username: postgres_user
- Password: postgres_password

You can connect using any PostgreSQL client, or use the psql command-line tool through Docker:
```bash
docker-compose exec db psql -U postgres_user -d db_local
```

### Adding New Python Packages

1. Add the package to `django_app/requirements/local.txt`
2. Rebuild the container:
   ```bash
   docker-compose build web
   docker-compose up -d
   ```

### Creating a New Django App

```bash
docker-compose exec web python manage.py startapp app_name
# Move the app to the apps directory
docker-compose exec web mv app_name apps/
```

Remember to update `apps.py` to use the correct name:
```python
# apps/app_name/apps.py
class AppNameConfig(AppConfig):
    name = 'apps.app_name'
```

## Configuration

### Environment Variables

The local environment uses the `.env.local` file in the `docker/local/` directory to configure services. Key variables include:

```
DEBUG=True
SECRET_KEY=local-development-secret-key
DJANGO_SETTINGS_MODULE=project_name.settings.local
POSTGRES_DB=db_local
POSTGRES_USER=postgres_user
POSTGRES_PASSWORD=postgres_password
```

### Django Settings

Local-specific Django settings are defined in `django_app/project_name/settings/local.py`. This file extends the base settings and adds development-specific configurations.

## Troubleshooting

### Common Issues

1. **Port conflicts**: If ports 8000, 5433, or 80 are already in use on your machine, you'll need to modify the port mappings in `docker-compose.yml`.

2. **Database connection issues**: If the web service cannot connect to the database, ensure that the database is running and that the credentials match those in the `.env.local` file.

3. **Permission issues with static/media files**: Check that the volumes are correctly mapped in `docker-compose.yml`.

4. **Changes not showing up**: Docker volumes can sometimes cache files. Try rebuilding the container with `docker-compose build web` and restarting with `docker-compose up -d`.

### Resetting the Environment

To completely reset your local environment:

```bash
docker-compose down -v
docker-compose build
docker-compose up -d
docker-compose exec web python manage.py migrate
docker-compose exec web python manage.py createsuperuser
```

## Transitioning to Staging/Production

When you're ready to test in a staging or production environment, refer to the corresponding README files:

- [README_STAGING.md](README_STAGING.md) - For the staging environment
- [README_PRODUCTION.md](README_PRODUCTION.md) - For the production environment