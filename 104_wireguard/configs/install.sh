#!/bin/bash

set -e
wg setconf wg0 /etc/wireguard/wg0.conf
qrcode -t png -o /etc/wireguard/wg0.png < /etc/wireguard/wg0.conf
