# Laboratorul 2 — Decuplare cu broker de mesaje (RabbitMQ)

**Limbaje:** Python (script), Java (compilat), Ruby (referință din arhivă)  
**Legătură cu Lab 1:** același crypto-puzzle — `SHA256("Hello World" + nonce)` cu **n** zerouri hex la începutul hash-ului (ex. Lab 1, n=6 → `Hello World1439621`).

## 1. Implementare

### a) Două computere în alte limbaje

| Fișier | Limbaj | Rol |
|--------|--------|-----|
| `python_computer.py` | Python | consumer RabbitMQ, SHA-256, partiție nonce |
| `java/Computer.java` | Java | consumer RabbitMQ, SHA-256, partiție nonce |
| `ruby_computer.rb` | Ruby | consumer original, extins cu partiție |

### b) Distribuirea sarcinii (`ruby_server.rb`)

Serverul trimite **câte un mesaj per worker**, cu câmpuri:

- `worker_id` — indexul workerului (0 … `worker_count-1`)
- `worker_count` — număr total de computere active

Fiecare computer caută doar `nonce`-uri: `worker_id`, `worker_id + worker_count`, … (ca la OpenMPI din Lab 1).

La primul răspuns valid, serverul publică semnal **`crypto-puzzle-stop`** (fanout) ca ceilalți workeri să oprească căutarea.

**Mediu:** Docker Compose — `computer_ruby`, `computer_python`, `computer_java`, `lab2_producer`, `rabbitmq`.

**Rulare:**

```bash
cd lab2/code
./run.sh 5
```

sau `./run.sh 6` (dificultate n).

### Rezultate măsurate (vezi `REZULTATE.md`)

| n | Lab 2 — 3 workers (ms) | Lab 1 secvențial (ms) | Lab 1 OpenMP ×4 (ms) |
|---|------------------------:|----------------------:|---------------------:|
| 4 | 4 204 | 40 | 10 |
| 5 | 81 544 | 236 | 68 |
| 6 | 73 573 | 480 | 139 |

---

## 2. Probleme tehnice întâlnite și rezolvări

| Problemă | Rezolvare |
|----------|-----------|
| Un singur consumer prelua toate mesajele | Serverul publică **N mesaje** (una per partiție); fiecare limbaj rulează un container consumer separat. |
| Workerii fără soluție în partiția lor rulau la infinit | Fanout **`crypto-puzzle-stop`** după primul răspuns; workerii verifică coada de stop în buclă. |
| RabbitMQ `Exit 0` pe Mac (volume `rabbitmq-data`) | Volumul de date nu e mapat în versiunea simplificată; brokerul pornește fără persistență locală problematică. |
| Java + JSON fără dependențe extra | Parsare minimală a câmpurilor din JSON în `Computer.java`; client AMQP din `amqp-client-5.20.0.jar`. |
| Correlation / reply-to | Păstrat modelul RPC din arhivă: `reply_to` + `correlation_id` (Bunny / Pika / Java client). |

---

## 3. Comparație RabbitMQ vs OpenMPI (Lab 1)

| Criteriu | RabbitMQ (Lab 2) | OpenMPI (Lab 1) |
|----------|------------------|-----------------|
| **Cuplare** | Temporală și tehnologică: producător/consumatori independenți, limbaje diferite | Tight coupling: același program, `MPI_Init`, rank/size |
| **Scalare** | Adaugi containere consumers; brokerul distribuie mesajele | `mpirun -np N` / cluster; partiție explicită în cod |
| **Comunicare** | Mesaje asincrone, cozi, opțional RPC | `MPI_Allreduce`, `MPI_Bcast` — sincronizare explicită |
| **Avantaje** | Decuplare reală; toleranță la căderea unui worker; mix de limbaje | Performanță mare pe HPC; overhead mic între procese pe același cluster |
| **Dezavantaje** | Latență broker, serializare JSON, configurare RabbitMQ | Un singur codebase C++; mai greu de extins cu servicii eterogene |
| **Lab 1 (măsurat, Docker)** | — | n=6: ~480 ms secvențial, ~139 ms OpenMP (4 fire) |
| **Lab 2 (măsurat, Docker)** | n=6: ~73 s (3 workers, Ruby+Python+Java) | — |

**Concluzie:** OpenMPI e potrivit când toți procesorii rulează același binar și vrei throughput maxim pe partiție comună. RabbitMQ e potrivit când vrei **servicii decuplate** (server + N computere heterogene), la costul latenței și al gestionării brokerului — similar în spirit cu accelerarea Lab 1, dar la nivel de **sistem distribuit**, nu de memorie partajată.

---

## 4. Comparație produse Queue / Message Broker

| Produs | Restricții tehnice | Preț (orientativ) | Documentație & exemple |
|--------|-------------------|-------------------|-------------------------|
| **RabbitMQ** | AMQP, exchange-uri, cozi; operare cluster posibilă, dar mai complexă decât Redis | Open source; hosting managed (CloudAMQP etc.) de la ~10–20 USD/lună | Foarte bună: [rabbitmq.com/getstarted](https://www.rabbitmq.com/getstarted.html), tutoriale oficiale |
| **Redis Pub/Sub** | Pub/Sub fără persistență garantată a mesajelor; nu e coadă clasică (fire-and-forget) | Open source; Redis Cloud free tier / plătit | Bună pentru Redis; Pub/Sub documentat, dar nu înlocuiește un broker de cozi |
| **Amazon SQS** | Managed AWS, latență, limite mesaj 256 KB, model pull | Pay-per-use (~0.40 USD / milion requests) | Excelentă în ecosistem AWS; SDK-uri multe limbaje |
| **Apache Kafka** | Log distribuit, throughput mare; overhead operare (ZooKeeper/KRaft) | Open source; Confluent Cloud plătit | Documentație voluminoasă; curbă de învățare mai mare |
| **NATS** | Lightweight, cloud-native; semantică simplă | Open source + NATS Cloud | Clară, orientată spre microservicii |

**Pentru acest laborator**, RabbitMQ se potrivește datorită modelului **queue + RPC reply-to**, folosit direct în `bunny` / `pika`.

---

## Structură fișiere (director `code/`)

```
code/
  run.sh
  default/
    docker-compose.yml
    Dockerfile
    ruby_server.rb
    ruby_computer.rb
    python_computer.py
    java/Computer.java
    start_cluster.sh
    stop_cluster.sh
```

---

*Completați numele studentului înainte de predare. Rulați `./run.sh` cu Docker pornit pentru a verifica soluția.*
