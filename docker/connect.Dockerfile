ARG connect_version
FROM confluentinc/cp-server-connect:${connect_version}

RUN confluent-hub install --no-prompt debezium/debezium-connector-mysql:1.9.7
RUN confluent-hub install --no-prompt debezium/debezium-connector-mongodb:1.6.0
RUN confluent-hub install --no-prompt jcustenborder/kafka-connect-spooldir:2.0.62
RUN confluent-hub install --no-prompt mongodb/kafka-connect-mongodb:1.8.1
RUN confluent-hub install --no-prompt confluentinc/kafka-connect-datagen:0.6.0
