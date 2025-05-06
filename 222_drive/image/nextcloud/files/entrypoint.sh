#!/bin/bash

set -xeu

echo "Start nextcloud at $(date)"

cd /var/www/nextcloud || exit 1

DB_TYPE=${DB_TYPE:-pgsql}
DB_HOST=${DB_HOST:-postgres}
DB_NAME=${DB_NAME:-nextcloud}
DB_USER=${DB_USER:-postgres}
DB_PASSWORD=${DB_PASSWORD:-password}
DB_ADMIN_USER=${DB_ADMIN_USER:-admin}
DB_ADMIN_PASSWORD=${DB_ADMIN_PASSWORD:-password}
DATA_DIR=${DATA_DIR:-'/var/www/nextcloud/data'}
FORCE_INSTALL=${FORCE_INSTALL:-false}


if [[ ! -f "$DATA_DIR/INSTALLED" ]] || $FORCE_INSTALL; then
  # install
  sudo -u www-data php occ maintenance:install -n -vv \
      --database="$DB_TYPE" \
      --database-host="$DB_HOST" \
      --database-name="$DB_NAME" \
      --database-user="$DB_USER" \
      --database-pass="$DB_PASSWORD" \
      --admin-user="$DB_ADMIN_USER" \
      --admin-pass="$DB_ADMIN_PASSWORD" \
      --data-dir="$DATA_DIR"
  touch "$DATA_DIR/INSTALLED"
else
  rm -f /var/www/nextcloud/config/CAN_INSTALL
fi

chown www-data:www-data /var/www/nextcloud/data
chmod 0770 /var/www/nextcloud/data

if [[ -f /var/www/nextcloud/init.sh ]]; then
  bash /var/www/nextcloud/init.sh
fi

/etc/init.d/apache2 start
#tail /var/log/apache2/* -f

OCC="sudo -u www-data php occ"

while true; do
  tail /var/log/apache2/access.log -F &
  tail /var/log/apache2/error.log -F &
  $OCC log:tail -f
#  tail /var/www/nextcloud/nextcloud.log -F || true
#  tail /var/log/apache2/other_vhosts_access.log -f
done