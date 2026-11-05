# Rezultate rulare — Lab 2 (+ comparație Lab 1)

**Data:** 2026-05-26  
**Mediu:** Docker Compose, RabbitMQ, 3 computere (`computer_ruby`, `computer_python`, `computer_java`)

## Lab 2 — RabbitMQ, 3 workers (Ruby + Python + Java)

| n | Soluție | Timp (ms) |
|---|---------|----------:|
| 4 | Hello World107105 | 4 204 |
| 5 | Hello World1717360 | 81 544 |
| 6 | Hello World1439621 | 73 573 |

*Partiție: `worker_id` / `worker_count` (ca Lab 1 MPI). Semnal `crypto-puzzle-stop` după primul răspuns.*

## Lab 1 — comparație (același puzzle, Docker Ubuntu)

### Secvențial (`default`)

| n | Soluție | Timp (ms) |
|---|---------|----------:|
| 4 | Hello World107105 | 40 |
| 5 | Hello World616577 | 236 |
| 6 | Hello World1439621 | 480 |

### OpenMP (4 fire)

| n | Soluție | Timp (ms) |
|---|---------|----------:|
| 4 | Hello World107105 | 10 |
| 5 | Hello World616577 | 68 |
| 6 | Hello World1439621 | 139 |

## Comparație orientativă (timp ms)

| n | Lab 1 secvențial | Lab 1 OpenMP ×4 | Lab 2 RabbitMQ ×3 |
|---|----------------:|----------------:|------------------:|
| 4 | 40 | 10 | 4 204 |
| 5 | 236 | 68 | 81 544 |
| 6 | 480 | 139 | 73 573 |

**Observații:**

- Lab 2 e mult mai lent: SHA-256 în Ruby/Python/Java interpretat + overhead mesaje RabbitMQ + verificare cozi stop.
- La **n=5**, Lab 2 a găsit alt nonce valid (`Hello World1717360`) — același număr de zerouri la hash, altă partiție/ordine de căutare.
- OpenMPI (Lab 1) rămâne cel mai eficient pentru calcul paralel pe același algoritm C++ compilat; RabbitMQ câștigă la **decuplare** (limbaje/ procesoare independente), nu la viteză brută.

## Reproducere

```bash
cd lab2/code
./run.sh 5
```

Rulare manuală cu dificultate:

```bash
cd lab2/code/default
docker compose up -d --build
docker compose exec -T lab2_producer env NONINTERACTIVE=1 DIFFICULTY=6 WORKER_COUNT=3 ruby ruby_server.rb
```
