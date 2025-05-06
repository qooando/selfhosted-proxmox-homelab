#!/bin/bash
set -e
docker-entrypoint.sh postgres -cconfig_file=/etc/postgres.conf

