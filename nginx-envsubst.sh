/bin/sh -c "envsubst < /etc/nginx/conf.d/templates/listen_plain.template > /etc/nginx/conf.d/listen_plain.active &&
  envsubst < /etc/nginx/conf.d/templates/listen_ssl.template > /etc/nginx/conf.d/listen_ssl.active &&
  envsubst < /etc/nginx/conf.d/templates/server_name.template > /etc/nginx/conf.d/server_name.active &&
  envsubst < /etc/nginx/conf.d/templates/sogo.template > /etc/nginx/conf.d/sogo.active &&
  envsubst < /etc/nginx/conf.d/templates/sogo_eas.template > /etc/nginx/conf.d/sogo_eas.active &&
  . /etc/nginx/conf.d/templates/sogo.auth_request.template.sh > /etc/nginx/conf.d/sogo_proxy_auth.active &&
  nginx -qt &&
  until ping phpfpm -c1 > /dev/null; do sleep 1; done &&
  until ping sogo -c1 > /dev/null; do sleep 1; done &&
  until ping redis -c1 > /dev/null; do sleep 1; done &&
  until ping rspamd -c1 > /dev/null; do sleep 1; done &&
  exec nginx -g 'daemon off;'"
