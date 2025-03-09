FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

WORKDIR /app

# Copy requirements first for better caching
COPY django_app/requirements /app/requirements/

# Install dependencies from requirements files
RUN pip install --upgrade pip && \
    pip install -r /app/requirements/staging.txt

# Copy project
COPY django_app /app/

# Create directories for static and media files
RUN mkdir -p /app/static /app/media

# Run the application
EXPOSE 8000
CMD ["gunicorn", "project_name.wsgi:application", "--bind", "0.0.0.0:8000", "--workers", "3"]