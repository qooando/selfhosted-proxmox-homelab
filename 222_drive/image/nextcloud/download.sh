#!/bin/bash
cd ./files || exit 1
wget https://download.nextcloud.com/server/releases/latest.tar.bz2
wget https://download.nextcloud.com/server/releases/latest.tar.bz2.sha256
sha256sum -c --ignore-missing latest.tar.bz2.sha256