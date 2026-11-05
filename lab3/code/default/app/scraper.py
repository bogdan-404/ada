import logging
import os
import re
import time
from urllib.parse import urljoin

from app.db import connect, exists, init_db, insert, count_all
from app.metrics import (
    ADVERTS_IN_DB,
    HTTP_REQUESTS,
    NEW_ADVERTS,
    SCRAPE_DURATION,
    SCRAPE_ERRORS,
    SCRAPE_RUNS,
    start_metrics_server,
)

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
log = logging.getLogger("scraper")

BASE_URL = os.getenv("SCRAPE_BASE_URL", "https://999.md")
LIST_URL = os.getenv(
    "SCRAPE_LIST_URL",
    "https://999.md/ro/list/transport/cars",
)
INTERVAL = int(os.getenv("SCRAPE_INTERVAL_SECONDS", "120"))
METRICS_PORT = int(os.getenv("METRICS_PORT", "8000"))
ID_RE = re.compile(r"999\.md/ro/(\d{6,12})")


def parse_advert_id(url: str) -> str | None:
    m = ID_RE.search(url)
    return m.group(1) if m else None


def scrape_with_playwright() -> list[dict]:
    from playwright.sync_api import sync_playwright

    items = []
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        page = browser.new_page(user_agent="ADA-Lab3-Scraper/1.0")
        HTTP_REQUESTS.inc()
        page.goto(LIST_URL, wait_until="networkidle", timeout=90000)
        page.wait_for_timeout(3000)
        cards = page.locator("a[href*='/ro/']")
        n = cards.count()
        seen = set()
        for i in range(min(n, 200)):
            href = cards.nth(i).get_attribute("href")
            if not href:
                continue
            advert_id = parse_advert_id(urljoin(BASE_URL, href))
            if not advert_id:
                continue
            url = f"{BASE_URL}/ro/{advert_id}"
            if advert_id in seen:
                continue
            seen.add(advert_id)
            title = ""
            price = ""
            try:
                card = cards.nth(i)
                title = (card.get_attribute("title") or card.inner_text() or "").strip()
                title = " ".join(title.split())[:500]
            except Exception:
                pass
            items.append({"id": advert_id, "url": url, "title": title, "price": price})
        browser.close()
    return items


def run_once():
    items = scrape_with_playwright()
    new_count = 0
    with connect() as conn:
        for item in items:
            if exists(conn, item["id"]):
                continue
            insert(conn, item["id"], item["url"], item["title"], item["price"])
            new_count += 1
            NEW_ADVERTS.inc()
            log.info("saved %s %s", item["id"], item["url"])
    ADVERTS_IN_DB.set(count_all())
    log.info("cycle done: found=%s new=%s total_db=%s", len(items), new_count, count_all())
    return new_count


def main():
    init_db()
    start_metrics_server(METRICS_PORT)
    log.info("scraper started list=%s interval=%ss", LIST_URL, INTERVAL)
    while True:
        SCRAPE_RUNS.inc()
        try:
            with SCRAPE_DURATION.time():
                run_once()
        except Exception as exc:
            SCRAPE_ERRORS.inc()
            log.exception("scrape failed: %s", exc)
        time.sleep(INTERVAL)


if __name__ == "__main__":
    main()
