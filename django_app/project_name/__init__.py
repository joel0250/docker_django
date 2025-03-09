# Import celery app so that it's always imported when Django starts
from .celery import app as celery_app

__all__ = ('celery_app',)