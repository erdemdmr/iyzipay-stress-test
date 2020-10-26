# Use a minimal base image with OpenJDK installed
FROM openjdk:8-jre-alpine3.7
# Install packages
RUN apk update && \
    apk add ca-certificates wget python python-dev py-pip && \
    update-ca-certificates && \
    pip install --upgrade --user awscli
# Set variables
ENV JMETER_HOME=/usr/share/apache-jmeter \
    JMETER_VERSION=5.3 \
    TEST_SCRIPT_FILE=/var/jmeter/test.jmx \
    TEST_RESULT_DIR=/var/jmeter/result \
    TEST_LOG_FILE=/var/jmeter/result/test.log \
    TEST_RESULTS_FILE=/var/jmeter/result/test-result.csv \
    USE_CACHED_SSL_CONTEXT=false \
    OPEN_CONNECTION_WAIT_TIME=5000 \
    OPEN_CONNECTION_TIMEOUT=20000 \
    OPEN_CONNECTION_READ_TIMEOUT=6000 \
    BEFORE_SEND_DATA_WAIT_TIME=5000 \
    SEND_DATA_WAIT_TIME=1000 \
    SEND_DATA_READ_TIMEOUT=6000 \
    CLOSE_CONNECTION_WAIT_TIME=5000 \
    CLOSE_CONNECTION_READ_TIMEOUT=6000 \
    NUMBER_OF_THREADS=100 \
    RAMP_UP_TIME=0 \
    LOOP_COUNT=10 \
    THROUGHPUT=1000 \
    PROTOCOL="http" \
    HOST=localhost \
    PORT=8080 \
    REQUEST_PATH="" \
    REQUEST_METHOD="GET" \
    AUTHORIZATION="" \
    AUTHORIZATION_PREFIX="IYZWS" \
    XIYZIRND="" \
    CONTENT_TYPE="application/json" \
    THREAD_GROUP_NAME="Test Thread Group" \
    AWS_ACCESS_KEY_ID=EXAMPLE \
    AWS_SECRET_ACCESS_KEY=EXAMPLEKEY \
    AWS_DEFAULT_REGION=eu-central-1 \
    PATH="~/.local/bin:$PATH" \
    JVM_ARGS="-Xms2048m -Xmx4096m -XX:NewSize=1024m -XX:MaxNewSize=2048m -Duser.timezone=UTC"
# Install Apache JMeter
RUN wget http://archive.apache.org/dist/jmeter/binaries/apache-jmeter-${JMETER_VERSION}.tgz && \
    tar zxvf apache-jmeter-${JMETER_VERSION}.tgz && \
    rm -f apache-jmeter-${JMETER_VERSION}.tgz && \
    mv apache-jmeter-${JMETER_VERSION} ${JMETER_HOME}
# Copy test plans
COPY jmeter/test-plan.jmx ${TEST_SCRIPT_FILE}
# Expose port
EXPOSE 443
# The main command, where several things happen:
# - Empty the log and result files
# - Start the JMeter script
# - Echo the log and result files' contents
CMD echo -n > $TEST_LOG_FILE && \
    echo -n > $TEST_RESULTS_FILE && \
    export PATH=~/.local/bin:$PATH && \
    $JMETER_HOME/bin/jmeter -n \
    -t=$TEST_SCRIPT_FILE \
    -j=$TEST_LOG_FILE \
    -l=$TEST_RESULTS_FILE \
    -Jhttps.use.cached.ssl.context=$USE_CACHED_SSL_CONTEXT \
    -Jjmeter.save.saveservice.output_format=csv \
    -Jjmeter.save.saveservice.response_data=true \
    -Jjmeter.save.saveservice.samplerData=true \
    -JopenConnectionWaitTime=$OPEN_CONNECTION_WAIT_TIME \
    -JopenConnectionConnectTimeout=$OPEN_CONNECTION_TIMEOUT \
    -JopenConnectionReadTimeout=$OPEN_CONNECTION_READ_TIMEOUT \
    -JbeforeSendDataWaitTime=$BEFORE_SEND_DATA_WAIT_TIME \
    -JsendDataWaitTime=$SEND_DATA_WAIT_TIME \
    -JsendDataReadTimeout=$SEND_DATA_READ_TIMEOUT \
    -JcloseConnectionWaitTime=$CLOSE_CONNECTION_WAIT_TIME \
    -JcloseConnectionReadTimeout=$CLOSE_CONNECTION_READ_TIMEOUT \
    -JnumberOfThreads=$NUMBER_OF_THREADS \
    -JrampUpTime=$RAMP_UP_TIME \
    -JloopCount=$LOOP_COUNT \
    -Jthroughput=$THROUGHPUT \
    -Jprotocol=$PROTOCOL \
    -Jhost=$HOST \
    -Jport=$PORT \
    -JrequestPath=$REQUEST_PATH \
    -JrequestMethod=$REQUEST_METHOD \
    -Jauthorization=$AUTHORIZATION \
    -JauthorizationPrefix=$AUTHORIZATION_PREFIX \
    -Jxiyzirnd=$XIYZIRND \
    -JcontentType=$CONTENT_TYPE \
    -JthreadGroupName=$THREAD_GROUP_NAME && \
    echo -e "\n\n===== UPLOADING THE FILES TO AWS S3 =====\n\n" && \
    aws s3 cp --recursive $TEST_RESULT_DIR s3://iyzipay-performance-test-logging/uploads/$THREAD_GROUP_NAME/