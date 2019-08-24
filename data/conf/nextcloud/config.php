# Set your nextcloud container's config located at /config/www/nextcloud/config/config.php
# and add the following lines before the ");":
#  'trusted_proxies' => ['nginx'],
#  'overwritewebroot' => '/nextcloud',
#  'overwrite.cli.url' => 'https://${OPENEMAIL_HOSTNAME}/nextcloud',
#
# Also don't forget to add your domain name to the trusted domains array. It should look somewhat like this:
#  array (
#    0 => '192.168.0.1:444', # This line may look different on your setup, don't modify it.
#    1 => '${YOURDOMAIN}',
#  ),
<?php
$openemail_hostname = getenv('OPENEMAIL_HOSTNAME');
$CONFIG = array (
  'memcache.local' => '\OC\Memcache\APCu',
  'datadirectory' => '/data',
  'trusted_proxies' => ['nginx'],
  'overwritewebroot' => '/nextcloud',
  'overwrite.cli.url' => 'https://$openemail_hostname/nextcloud',
  'trusted_domains' =>
     array (
     0 => '$openemail_hostname',
   ),
);
