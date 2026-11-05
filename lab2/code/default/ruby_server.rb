# frozen_string_literal: true

require 'bunny'
require 'securerandom'
require 'json'

user = 'guest'
password = 'guest'
host = ENV.fetch('RABBITMQ_HOST', 'rabbitmq')
queue_name = 'crypto-puzzle-inquiries'
stop_exchange = 'crypto-puzzle-stop'
worker_count = Integer(ENV.fetch('WORKER_COUNT', '3'))

connection = Bunny.new "amqp://#{user}:#{password}@#{host}"
connection.start

lock = Mutex.new
condition = ConditionVariable.new
@done = false
@start_time = nil

channel = connection.create_channel
exchange = channel.default_exchange
channel.queue(queue_name, auto_delete: true)
stop_fanout = channel.fanout(stop_exchange)
reply_queue = channel.queue('', exclusive: true, auto_delete: true)

reply_queue.subscribe do |_delivery_info, _properties, payload|
  lock.synchronize do
    next if @done

    @done = true
    elapsed_ms = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - @start_time) * 1000).round
    puts "Solutie: #{payload}"
    puts "Timp: #{elapsed_ms} ms"
    stop_fanout.publish('stop')
    condition.signal
  end
end

def run_puzzle(difficulty, worker_count, exchange, queue_name, reply_queue, lock, condition)
  lock.synchronize { @done = false }
  @start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  puts "Dificultate #{difficulty}, repartizare pe #{worker_count} computere..."

  worker_count.times do |worker_id|
    payload = {
      string: 'Hello World',
      difficulty: difficulty,
      worker_id: worker_id,
      worker_count: worker_count
    }
    exchange.publish(
      payload.to_json,
      routing_key: queue_name,
      correlation_id: SecureRandom.uuid,
      reply_to: reply_queue.name
    )
  end

  lock.synchronize { condition.wait(lock) until @done }
end

if ENV['NONINTERACTIVE'] == '1'
  run_puzzle(Integer(ENV.fetch('DIFFICULTY', '5')), worker_count, exchange, queue_name, reply_queue, lock, condition)
else
  begin
    loop do
      puts 'Ctrl+C pentru iesire'
      print 'Dificultate (1-8): '
      difficulty = $stdin.gets.to_i
      if (1..8).include?(difficulty)
        run_puzzle(difficulty, worker_count, exchange, queue_name, reply_queue, lock, condition)
      else
        puts "Valoare invalida: #{difficulty}"
      end
    end
  rescue Interrupt
    puts
  end
end

channel.close
connection.close
