#!/bin/bash
set -eu

cd /var/www/nextcloud || exit 1

OCC="sudo -u www-data php occ"

echo "Fix certificates"
$OCC security:certificates:import /etc/ssl/certs/ca-certificates.crt

echo "Fix htaccess"
$OCC maintenance:update:htaccess

echo "Fix mimetypes"
$OCC maintenance:repair --include-expensive

echo "Fix indices"
$OCC db:add-missing-indices

echo "Set maintenance window"
$OCC config:system:set maintenance_window_start --type=integer --value=1

echo "Set cron"
echo "*/5  *  *  *  * php -f /var/www/nextcloud/cron.php" | crontab -u www-data -
/etc/init.d/cron start


echo "Disable some apps"
$OCC app:disable \
  activity \
  dashboard \
  photos \
  user_ldap \
  || true

# https://docs.goauthentik.io/integrations/services/nextcloud/
echo "Configure Authentik OAuth2"
$OCC app:enable user_oidc
$OCC user_oidc:provider Authentik \
  --clientid='${oauth2_client_id}' \
  --clientsecret='${oauth2_client_secret}' \
  --discoveryuri='${discovery_uri}' \
  --scope="email profile" \
  --mapping-uid="email" \
  --mapping-email="email" \
  --mapping-display-name="name" \
  --mapping-quota="" \
  --mapping-groups="" \
  --unique-uid=0
