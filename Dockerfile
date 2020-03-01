FROM alpine:latest

RUN apk add --update bash mysql-client gzip openssl \
    && apk add --repository http://dl-cdn.alpinelinux.org/alpine/v3.6/main postgresql~=9.6 \
    && rm -rf /var/cache/apk/*

ENV CRON_TIME="0 3 * * sun" \
    MYSQL_HOST="mysql" \
    MYSQL_PORT="3306" \
    TIMEOUT="10s"

COPY ["run.sh", "backup.sh", "/"]
RUN mkdir /mysql_backup && chmod u+x /backup.sh /run.sh
VOLUME ["/mysql_backup"]
ENTRYPOINT ["/run.sh"]