#!/bin/bash
[ -z "${MYSQL_USER}" ] && { echo "=> MYSQL_USER cannot be empty" && exit 1; }
[ -z "${MYSQL_PASS:=$MYSQL_PASSWORD}" ] && { echo "=> MYSQL_PASS cannot be empty" && exit 1; }

DATE=$(date +%Y%m%d%H%M)
echo "=> Backup started at $(date "+%Y-%m-%d %H:%M:%S")"
DATABASES=${MYSQL_DATABASE:-${MYSQL_DB:-$(mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -p"$MYSQL_PASS" -e "SHOW DATABASES;" | tr -d "| " | grep -v Database)}}
DB_COUNTER=0
for db in ${DATABASES}
do
  if [[ "$db" != "information_schema" ]] && [[ "$db" != "performance_schema" ]] && [[ "$db" != "mysql" ]] && [[ "$db" != _* ]]
  then
    echo "==> Dumping database: $db"
    FILENAME=/mysql_backup/$DATE.$db.sql
    LATEST=/mysql_backup/latest.$db.sql.gz
    if mysqldump -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -p"$MYSQL_PASS" --databases "$db" $MYSQLDUMP_OPTS > "$FILENAME"
    then
      gzip -f "$FILENAME"
      echo "==> Creating symlink to latest backup: $(basename "$FILENAME".gz)"
      rm "$LATEST" 2> /dev/null
      cd /mysql_backup && ln -s $(basename "$FILENAME".gz) $(basename "$LATEST") && cd -
      DB_COUNTER=$(( DB_COUNTER + 1 ))
    else
      rm -rf "$FILENAME"
    fi
  fi
done

POSTGRES_DATABASES=`psql -h $POSTGRESQL_HOST -U $POSTGRESQL_USER -q -c "\l" | sed -n 4,/\eof/p | grep -v rows\) | grep -v template0 | grep -v template1 | awk {'print $1'}`
for pdb in ${POSTGRES_DATABASES}
do
  if [[ "$pdb" != "postgres" ]] && [[ "$pdb" != "root" ]] && [[ "$pdb" != "|" ]]
  then
    echo "==> Dumping postgres: $pdb"
    pg_dump -U $POSTGRESQL_USER -h $POSTGRESQL_HOST -table="$pdb" > /postgres_backup/$DATE.$pdb.dump
  fi
done

if [ -n "$MAX_BACKUPS" ]
then
  MAX_FILES=$(( MAX_BACKUPS * DB_COUNTER ))
  while [ "$(find /mysql_backup -maxdepth 1 -name "*.sql.gz" -type f | wc -l)" -gt "$MAX_FILES" ]
  do
    TARGET=$(find /mysql_backup -maxdepth 1 -name "*.sql.gz" -type f | sort | head -n 1)
    echo "==> Max number of backups ($MAX_BACKUPS) reached. Deleting ${TARGET} ..."
    rm -rf "${TARGET}"
    echo "==> Backup ${TARGET} deleted"
  done

  while [ "$(find /postgres_backup -maxdepth 1 -name "*.dump" -type f | wc -l)" -gt "$MAX_FILES" ]
  do
    TARGET=$(find /postgres_backup -maxdepth 1 -name "*.dump" -type f | sort | head -n 1)
    echo "==> Max number of backups ($MAX_BACKUPS) reached. Deleting ${TARGET} ..."
    rm -rf "${TARGET}"
    echo "==> Backup ${TARGET} deleted"
  done
fi

echo "=> Backup process finished at $(date "+%Y-%m-%d %H:%M:%S")"