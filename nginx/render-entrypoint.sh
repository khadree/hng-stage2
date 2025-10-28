#!/bin/sh
set -eu


TEMPLATE=/etc/nginx/nginx.conf.template
OUT=/etc/nginx/nginx.conf


# envsubst will expand variables like $ACTIVE_POOL, $BLUE_HOST, $GREEN_HOST, $APP_PORT
# but we also need to set which server is marked "backup". Template expects placeholders BACKUP_MARKER_BLUE and BACKUP_MARKER_GREEN.


# Determine backup placement
if [ "${ACTIVE_POOL:-blue}" = "blue" ]; then
BACKUP_MARKER_BLUE=
BACKUP_MARKER_GREEN=backup
else
BACKUP_MARKER_BLUE=backup
BACKUP_MARKER_GREEN=
fi


export BACKUP_MARKER_BLUE BACKUP_MARKER_GREEN


# generate final config
envsubst < "$TEMPLATE" > "$OUT"


# Let original nginx entrypoint continue
exec /docker-entrypoint.sh nginx -g "daemon off;"