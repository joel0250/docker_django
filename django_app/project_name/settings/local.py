"""
Local settings for project_name project.
"""
import os
from .base import *  # noqa

# SECURITY WARNING: keep the secret key used in production secret!
SECRET_KEY = os.environ.get('SECRET_KEY', 'django-insecure-development-key')

# SECURITY WARNING: don't run with debug turned on in production!
DEBUG = os.environ.get('DEBUG', 'False') == 'True'

ALLOWED_HOSTS = ['localhost', '127.0.0.1', '0.0.0.0']

# Database - use direct settings for local development
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': os.environ.get('POSTGRES_DB', 'db_local'),
        'USER': os.environ.get('POSTGRES_USER', 'postgres_user'),
        'PASSWORD': os.environ.get('POSTGRES_PASSWORD', 'postgres_password'),
        'HOST': os.environ.get('POSTGRES_HOST', 'db'),
        'PORT': os.environ.get('POSTGRES_PORT', '5432'),
    }
}

# Email
EMAIL_BACKEND = 'django.core.mail.backends.console.EmailBackend'