#!/bin/bash
set -e
WEB_BRANCH="master"
CORE_BRANCH="master"
FTL_BRANCH="master"
PIHOLE_DOCKER_TAG="dev-localbuild"
PADD_BRANCH="master"
PIHOLE_UID=1000
PIHOLE_GID=1000
DNSMASQ_USER=pihole
FTL_CMD=no-daemon

curl -k https://raw.githubusercontent.com/pi-hole/PADD/${PADD_BRANCH}/padd.sh > /usr/local/bin/padd
chmod 0755 /usr/local/bin/padd

git clone --depth 1 --single-branch --branch ${WEB_BRANCH} https://github.com/pi-hole/web.git /var/www/html/admin && \
git clone --depth 1 --single-branch --branch ${CORE_BRANCH} https://github.com/pi-hole/pi-hole.git /etc/.pihole
cd /etc/.pihole && \
install -Dm755 -d /opt/pihole
install -Dm755 -t /opt/pihole gravity.sh
install -Dm755 -t /opt/pihole ./advanced/Scripts/*.sh
install -Dm755 -t /opt/pihole ./advanced/Scripts/COL_TABLE
install -Dm755 -d /etc/pihole
install -Dm644 -t /etc/pihole ./advanced/Templates/logrotate
install -Dm755 -d /var/log/pihole
install -Dm755 -d /var/lib/logrotate
install -Dm755 -t /usr/local/bin pihole
install -Dm644 ./advanced/bash-completion/pihole /etc/bash_completion.d/pihole
install -T -m 0755 ./advanced/Templates/pihole-FTL-prestart.sh /opt/pihole/pihole-FTL-prestart.sh
install -T -m 0755 ./advanced/Templates/pihole-FTL-poststop.sh /opt/pihole/pihole-FTL-poststop.sh
addgroup -S pihole -g ${PIHOLE_GID} && adduser -S pihole -G pihole -u ${PIHOLE_UID}
echo "${PIHOLE_DOCKER_TAG}" > /pihole.docker.tag
chmod 0755 /usr/bin/start.sh
FTLARCH=amd64
echo "Arch: ${TARGETPLATFORM}, FTLARCH: ${FTLARCH}"
if [ "${FTL_BRANCH}" = "master" ]; then
  URL="https://github.com/pi-hole/ftl/releases/latest/download";
else
  URL="https://ftl.pi-hole.net/${FTL_BRANCH}";
fi

curl -sSL "${URL}/pihole-FTL-${FTLARCH}" -o /usr/bin/pihole-FTL
chmod +x /usr/bin/pihole-FTL
readelf -h /usr/bin/pihole-FTL || (echo "Error with downloaded FTL binary" && exit 1)
/usr/bin/pihole-FTL -vv
chmod +x /etc/init.d/pihole
rc-update add pihole
#service pihole restart
#service pihole start
#dig -p $(pihole-FTL --config dns.port) +short +norecurse +retry=0 @127.0.0.1 pi.hole || exit 1
