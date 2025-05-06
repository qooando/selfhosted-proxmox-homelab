<?php
$CONFIG = array (
    'htaccess.RewriteBase' => '/',
    'overwrite.cli.url' => 'https://${hostname}',
    'overwritehost' => '${hostname}',
    'overwriteprotocol' => 'https',
    'trusted_domains' => array (
        0 => 'localhost',
        1 => '${hostname}'
    ),
    'trusted_proxies' => array(
        0 => '127.0.0.1',
        1 => '10.42.0.0/16'
        ),
    'forwarded_for_headers' => array(
        0 => 'HTTP_CF_CONNECTING_IP',
        1 => 'HTTP_X_FORWARDED_FOR',
        2 => 'HTTP_HOST'
        ),
    'allow_local_remote_servers' => true,
    'auth.bruteforce.protection.enabled' => false,
);
