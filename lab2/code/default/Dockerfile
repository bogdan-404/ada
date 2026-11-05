FROM ubuntu:22.04
ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update --fix-missing && apt-get install -y \
    ruby ruby-dev python3 python3-pip openjdk-17-jdk-headless curl \
    && gem install bunny \
    && pip3 install --no-cache-dir pika \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /home/student/lab2/java/lib \
    && curl -fsSL -o /home/student/lab2/java/lib/amqp-client-5.20.0.jar \
      https://repo1.maven.org/maven2/com/rabbitmq/amqp-client/5.20.0/amqp-client-5.20.0.jar

COPY java/Computer.java /home/student/lab2/java/Computer.java
RUN javac -cp /home/student/lab2/java/lib/amqp-client-5.20.0.jar \
    -d /home/student/lab2/java /home/student/lab2/java/Computer.java

WORKDIR /home/student/lab2
CMD ["ruby", "ruby_computer.rb"]
