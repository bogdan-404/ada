from prometheus_client import Counter, Gauge, Histogram, start_http_server

SCRAPE_RUNS = Counter("scraper_runs_total", "Scraper loop iterations")
SCRAPE_ERRORS = Counter("scraper_errors_total", "Scraper failures")
HTTP_REQUESTS = Counter("scraper_http_requests_total", "HTTP requests during scrape")
NEW_ADVERTS = Counter("scraper_new_adverts_total", "New adverts saved to DB")
ADVERTS_IN_DB = Gauge("scraper_adverts_in_db", "Total adverts in database")
SCRAPE_DURATION = Histogram("scraper_scrape_duration_seconds", "Scrape cycle duration")


def start_metrics_server(port: int):
    start_http_server(port)
