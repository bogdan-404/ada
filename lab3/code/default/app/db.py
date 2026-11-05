import os
import sqlite3
from datetime import datetime, timezone

DB_PATH = os.getenv("DB_PATH", "/data/adverts.db")


def connect():
    os.makedirs(os.path.dirname(DB_PATH), exist_ok=True)
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn


def init_db():
    with connect() as conn:
        conn.execute(
            """
            CREATE TABLE IF NOT EXISTS adverts (
                id TEXT PRIMARY KEY,
                url TEXT UNIQUE NOT NULL,
                title TEXT,
                price TEXT,
                created_at TEXT NOT NULL
            )
            """
        )
        conn.commit()


def exists(conn, advert_id: str) -> bool:
    row = conn.execute("SELECT 1 FROM adverts WHERE id = ?", (advert_id,)).fetchone()
    return row is not None


def insert(conn, advert_id: str, url: str, title: str, price: str):
    conn.execute(
        "INSERT INTO adverts (id, url, title, price, created_at) VALUES (?, ?, ?, ?, ?)",
        (advert_id, url, title, price, datetime.now(timezone.utc).isoformat()),
    )
    conn.commit()


def count_all() -> int:
    with connect() as conn:
        return conn.execute("SELECT COUNT(*) FROM adverts").fetchone()[0]
