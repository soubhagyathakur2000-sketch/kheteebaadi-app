from celery import Celery
from celery.schedules import crontab
from app.core.config import settings

# Create Celery app
celery_app = Celery(
    "kheteebaadi",
    broker=settings.REDIS_URL,
    backend=settings.REDIS_URL,
)

# Configure Celery
celery_app.conf.update(
    task_serializer="json",
    accept_content=["json"],
    result_serializer="json",
    timezone="UTC",
    enable_utc=True,
    result_expires=3600,
    task_track_started=True,
    task_time_limit=30 * 60,  # 30 minutes hard limit
)

# Task routes
celery_app.conf.task_routes = {
    "app.workers.tasks.refresh_mandi_prices": {"queue": "default"},
    "app.workers.tasks.send_notification": {"queue": "notifications"},
    "app.workers.tasks.cleanup_expired_sync_logs": {"queue": "maintenance"},
    "app.workers.tasks.generate_daily_report": {"queue": "reports"},
}

# Celery Beat schedule
celery_app.conf.beat_schedule = {
    "refresh-mandi-prices": {
        "task": "app.workers.tasks.refresh_mandi_prices",
        "schedule": crontab(minute=0),  # Every hour
    },
    "cleanup-sync-logs": {
        "task": "app.workers.tasks.cleanup_expired_sync_logs",
        "schedule": crontab(hour=2, minute=0),  # 2 AM daily
    },
    "generate-daily-report": {
        "task": "app.workers.tasks.generate_daily_report",
        "schedule": crontab(hour=23, minute=59),  # 11:59 PM daily
    },
}
