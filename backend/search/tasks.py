"""Search analytics off the request thread.

`enqueue` tries Celery first (async when a worker + Redis broker are up)
and falls back to running the task inline when the broker is unreachable —
local dev without Docker must never 500 just because analytics couldn't be
queued.
"""

import logging

from celery import shared_task

logger = logging.getLogger(__name__)


def enqueue(task, **kwargs):
    """Dispatch a task async; run inline if the broker is down."""
    try:
        task.delay(**kwargs)
    except Exception:  # broker unreachable / EAGER mode raising / etc.
        logger.warning("Celery broker unavailable — running %s inline", task.name)
        try:
            task.apply(kwargs=kwargs).get()
        except Exception:
            logger.exception("Inline fallback for %s failed", task.name)


@shared_task(bind=True, max_retries=3, default_retry_delay=30, ignore_result=True)
def log_search_query(self, query, user_id, results_count, filters, took_ms):
    from django.contrib.auth import get_user_model

    from .models import SearchQueryLog

    User = get_user_model()
    SearchQueryLog.objects.create(
        query=query,
        user=User.objects.filter(pk=user_id).first() if user_id else None,
        results_count=results_count,
        filters=filters or {},
        took_ms=took_ms,
    )


@shared_task(bind=True, max_retries=3, default_retry_delay=30, ignore_result=True)
def bump_popular_search(self, query):
    from .models import PopularSearch

    popular, _ = PopularSearch.objects.get_or_create(query=query)
    popular.increment()
