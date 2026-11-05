# frozen_string_literal: true

require 'bunny'
require 'digest/sha2'
require 'json'

user = 'guest'
password = 'guest'
host = ENV.fetch('RABBITMQ_HOST', 'rabbitmq')
queue_name = 'crypto-puzzle-inquiries'
stop_exchange = 'crypto-puzzle-stop'

def solve_crypto_puzzle(string, difficulty, worker_id, worker_count, channel, stop_queue)
  sha256 = Digest::SHA256.new
  needle = '0' * difficulty
  n = worker_id
  loop do
    delivery, = channel.basic_get(stop_queue, manual_ack: true)
    return nil if delivery

    solution_candidate = string + n.to_s
    result = sha256.hexdigest(solution_candidate)
    return solution_candidate if result[0...difficulty] == needle

    n += worker_count
  end
end

connection = Bunny.new "amqp://#{user}:#{password}@#{host}"
connection.start

channel = connection.create_channel
exchange = channel.default_exchange
channel.fanout(stop_exchange)
stop_queue = channel.queue('', exclusive: true, auto_delete: true).name
channel.queue_bind(stop_queue, stop_exchange)

queue = channel.queue(queue_name, auto_delete: true)
queue.subscribe(block: true, manual_ack: true) do |delivery_info, properties, payload|
  json_payload = JSON.parse(payload)
  solution = solve_crypto_puzzle(
    json_payload['string'],
    json_payload['difficulty'],
    json_payload['worker_id'],
    json_payload['worker_count'],
    channel,
    stop_queue
  )

  if solution
    exchange.publish(
      solution,
      routing_key: properties.reply_to,
      correlation_id: properties.correlation_id
    )
  end
  channel.ack(delivery_info.delivery_tag)
end
