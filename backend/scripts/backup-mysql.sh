#!/usr/bin/env bash
# Резервная копия MySQL для продакшена.
# Использование:
#   export DB_HOST=... DB_USER=... DB_PASSWORD=... DB_NAME=creative_collective
#   ./scripts/backup-mysql.sh /path/to/backups
#
# Cron (ежедневно в 03:15):
#   15 3 * * * DB_HOST=... DB_USER=... DB_PASSWORD=... DB_NAME=... /app/backup-mysql.sh /backups >> /var/log/mysql-backup.log 2>&1
set -euo pipefail

DEST_DIR="${1:-./backups}"
mkdir -p "$DEST_DIR"

STAMP="$(date +%Y%m%d_%H%M%S)"
FILE="$DEST_DIR/${DB_NAME:-creative_collective}_${STAMP}.sql.gz"

: "${DB_HOST:?Set DB_HOST}"
: "${DB_USER:?Set DB_USER}"
: "${DB_PASSWORD:?Set DB_PASSWORD}"
DB_NAME="${DB_NAME:-creative_collective}"

mysqldump \
  -h "$DB_HOST" \
  -P "${DB_PORT:-3306}" \
  -u "$DB_USER" \
  -p"$DB_PASSWORD" \
  --single-transaction \
  --routines \
  --triggers \
  --set-gtid-purged=OFF \
  "$DB_NAME" | gzip -c > "$FILE"

echo "Backup written: $FILE"
# Удалить дампы старше 14 дней (опционально)
find "$DEST_DIR" -name "*.sql.gz" -mtime +14 -delete 2>/dev/null || true
