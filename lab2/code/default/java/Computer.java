import com.rabbitmq.client.AMQP;
import com.rabbitmq.client.Channel;
import com.rabbitmq.client.Connection;
import com.rabbitmq.client.ConnectionFactory;
import com.rabbitmq.client.DefaultConsumer;
import com.rabbitmq.client.Envelope;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;

public class Computer {
    private static final String QUEUE = "crypto-puzzle-inquiries";
    private static final String STOP_EX = "crypto-puzzle-stop";

    static int jsonInt(String json, String key) {
        String p = "\"" + key + "\":";
        int i = json.indexOf(p);
        if (i < 0) {
            return 0;
        }
        i += p.length();
        int j = i;
        while (j < json.length() && (Character.isDigit(json.charAt(j)) || json.charAt(j) == '-')) {
            j++;
        }
        return Integer.parseInt(json.substring(i, j));
    }

    static String jsonString(String json, String key) {
        String p = "\"" + key + "\":\"";
        int i = json.indexOf(p);
        if (i < 0) {
            return "";
        }
        i += p.length();
        int j = json.indexOf('"', i);
        return json.substring(i, j);
    }

    static String solve(String string, int difficulty, int workerId, int workerCount, Channel channel, String stopQueue)
            throws Exception {
        String needle = "0".repeat(difficulty);
        MessageDigest sha = MessageDigest.getInstance("SHA-256");
        long n = workerId;
        while (true) {
            if (channel.basicGet(stopQueue, true) != null) {
                return null;
            }
            String candidate = string + n;
            byte[] hash = sha.digest(candidate.getBytes(StandardCharsets.UTF_8));
            sha.reset();
            String hex = toHex(hash);
            if (hex.startsWith(needle)) {
                return candidate;
            }
            n += workerCount;
        }
    }

    static String toHex(byte[] bytes) {
        StringBuilder sb = new StringBuilder(bytes.length * 2);
        for (byte b : bytes) {
            sb.append(String.format("%02x", b));
        }
        return sb.toString();
    }

    public static void main(String[] args) throws Exception {
        String host = System.getenv().getOrDefault("RABBITMQ_HOST", "rabbitmq");
        ConnectionFactory factory = new ConnectionFactory();
        factory.setHost(host);
        factory.setUsername("guest");
        factory.setPassword("guest");

        Connection connection = factory.newConnection();
        Channel channel = connection.createChannel();
        channel.queueDeclare(QUEUE, false, false, true, null);
        channel.exchangeDeclare(STOP_EX, "fanout");
        String stopQueue = channel.queueDeclare("", false, true, true, null).getQueue();
        channel.queueBind(stopQueue, STOP_EX, "");

        DefaultConsumer consumer = new DefaultConsumer(channel) {
            @Override
            public void handleDelivery(String consumerTag, Envelope envelope, AMQP.BasicProperties properties, byte[] body) {
                try {
                    String json = new String(body, StandardCharsets.UTF_8);
                    String solution = solve(
                            jsonString(json, "string"),
                            jsonInt(json, "difficulty"),
                            jsonInt(json, "worker_id"),
                            jsonInt(json, "worker_count"),
                            channel,
                            stopQueue
                    );
                    if (solution != null) {
                        channel.basicPublish("", properties.getReplyTo(),
                                new AMQP.BasicProperties.Builder().correlationId(properties.getCorrelationId()).build(),
                                solution.getBytes(StandardCharsets.UTF_8));
                    }
                    channel.basicAck(envelope.getDeliveryTag(), false);
                } catch (Exception e) {
                    throw new RuntimeException(e);
                }
            }
        };
        channel.basicConsume(QUEUE, false, consumer);
        Thread.currentThread().join();
    }
}
