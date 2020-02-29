FROM alpine:latest

RUN apk add --update bash mysql-client gzip openssl && rm -rf /var/cache/apk/*

ENV CRON_TIME="0 3 * * sun" \
    MYSQL_HOST="mysql" \
    MYSQL_PORT="3306" \
    TIMEOUT="10s"

COPY ["run.sh", "backup.sh", "/"]
RUN mkdir /mysql_backup && chmod u+x /backup.sh
VOLUME ["/mysql_backup"]

CMD dockerize -wait tcp://${MYSQL_HOST}:${MYSQL_PORT} -timeout ${TIMEOUT} /run.sh