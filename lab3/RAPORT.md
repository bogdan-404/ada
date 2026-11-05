# Laboratorul 3 — Monitorizare Prometheus & Grafana

**Tema:** Monitorizarea unui sistem distribuit cu Prometheus + Grafana.  
**Aplicație monitorizată:** scraper Python pentru anunțuri [999.md](https://999.md) (categorie mașini), salvează în SQLite doar anunțurile noi.

## 1) Informație generală (Prometheus & Grafana)

**Prometheus** este un sistem de monitorizare care colectează metrici în timp (time-series) prin model **pull** (scrape) de la endpoint-uri HTTP de tip `/metrics`. Metricile sunt stocate și interogate cu **PromQL**.

**Grafana** este un instrument de vizualizare: conectezi o sursă de date (Prometheus) și construiești dashboard-uri (grafice/alerte) pe baza interogărilor PromQL.

În această lucrare:
- `node-exporter` expune metrici despre nod (CPU, memorie, disk).
- aplicația `scraper` expune metrici custom + metrici de proces Python.
- Prometheus scrapează ambele ținte.
- Grafana afișează dashboard-ul.

## 2) Rulare / Oprire

Pornire:

```bash
cd lab3/code
./run.sh
```

Oprire:

```bash
cd lab3/code/default
./stop_cluster.sh
```

URL-uri:

| Serviciu | URL |
|----------|-----|
| Grafana | http://localhost:3000 — `admin` / `admin` |
| Prometheus | http://localhost:9090 |
| Scraper metrics | http://localhost:8000/metrics |

Dashboard: **ADA Lab3 - 999.md Scraper** (provisionat automat).

## 3) Monitorizare CPU și Memorie (node-exporter)

Metrici folosite (PromQL):

- **CPU load**: `node_load1`
- **Memorie ocupată**: `node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes`

În Grafana aceste două panouri trebuie să aibă date și să varieze în timp.

## 4) Monitorizare spațiu de stocare HDD/SSD (node-exporter)

Pentru disk folosim:

`node_filesystem_size_bytes{fstype!~"tmpfs|overlay"} - node_filesystem_avail_bytes{fstype!~"tmpfs|overlay"}`

Notă: pe macOS (Docker Desktop), mountpoint-urile nu arată ca pe Linux (`/`), ci pot fi `/var/lib`, `/host_mnt/...`, etc. Important este să existe **date pe grafic**.

## 5) Dashboard-uri aplicație web (request-uri/min + memorie aplicație)

Aplicația `scraper` expune metrici Prometheus:

- **Request-uri / min**: `rate(scraper_http_requests_total[1m]) * 60`
- **Rulari / min**: `rate(scraper_runs_total[1m]) * 60`
- **Memorie proces**: `process_resident_memory_bytes{job="scraper"}`
- **Anunțuri în DB**: `scraper_adverts_in_db`

### Rezultate (rulare curentă)

- `scraper_adverts_in_db = 2737` (confirmat și în SQLite)
- `rate(scraper_http_requests_total[1m]) * 60` poate fi 0 între cicluri (scraper rulează la interval, implicit 120s) și crește în momentul rulării unui scrape.

## 6) Implementare (scraper + DB)

- Scraper: Python + Playwright (Chromium headless) — 999.md încarcă anunțurile prin JavaScript.
- Periodicitate: `SCRAPE_INTERVAL_SECONDS` (implicit 120s).
- Logică: colectează linkuri către anunțuri `/ro/<id>`, inserează în SQLite doar ID-urile care nu există încă.
- DB: SQLite în volum Docker (`scraper_data`, fișier `/data/adverts.db`).

## 7) Ce screenshots se includ în raport

Minim (acoperă punctele 2–4 din cerință):

1. **Grafana dashboard overview** (ADA Lab3 - 999.md Scraper)
2. **CPU load (node)** (panel)
3. **Memorie ocupată (node)** (panel)
4. **Spațiu disk folosit (node)** (panel)
5. **Request-uri scraper / min** (panel) și/sau **Memorie proces scraper** (panel)
6. **Prometheus → Status → Targets** (ținte `node` și `scraper` = UP)

## Legătură Lab 1–2 (context)

| Lab | Rol |
|-----|-----|
| Lab 1 | performanță CPU (OpenMP/MPI) |
| Lab 2 | decuplare componente (RabbitMQ) |
| Lab 3 | observabilitate: resurse nod + aplicație (scraper) |
