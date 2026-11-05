#!/usr/bin/env python3
import hashlib
import json
import os

import pika

HOST = os.getenv("RABBITMQ_HOST", "rabbitmq")
QUEUE = "crypto-puzzle-inquiries"
STOP_EX = "crypto-puzzle-stop"


def solve(string, difficulty, worker_id, worker_count, channel, stop_queue):
    needle = "0" * difficulty
    n = worker_id
    while True:
        method, _, _ = channel.basic_get(queue=stop_queue, auto_ack=True)
        if method:
            return None
        candidate = string + str(n)
        if hashlib.sha256(candidate.encode()).hexdigest()[:difficulty] == needle:
            return candidate
        n += worker_count


def main():
    creds = pika.PlainCredentials("guest", "guest")
    conn = pika.BlockingConnection(pika.ConnectionParameters(host=HOST, credentials=creds))
    ch = conn.channel()
    ch.queue_declare(queue=QUEUE, auto_delete=True)
    ch.exchange_declare(exchange=STOP_EX, exchange_type="fanout")
    stop_q = ch.queue_declare(queue="", exclusive=True).method.queue
    ch.queue_bind(exchange=STOP_EX, queue=stop_q)

    def on_message(channel, method, properties, body):
        data = json.loads(body)
        solution = solve(
            data["string"],
            int(data["difficulty"]),
            int(data["worker_id"]),
            int(data["worker_count"]),
            channel,
            stop_q,
        )
        if solution:
            channel.basic_publish(
                exchange="",
                routing_key=properties.reply_to,
                properties=pika.BasicProperties(correlation_id=properties.correlation_id),
                body=solution,
            )
        channel.basic_ack(delivery_tag=method.delivery_tag)

    ch.basic_consume(queue=QUEUE, on_message_callback=on_message, auto_ack=False)
    ch.start_consuming()


if __name__ == "__main__":
    main()
