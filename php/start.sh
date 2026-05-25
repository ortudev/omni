#!/bin/bash
set -e

echo "[start] Linking shared PHP configs..."

for VERSION in $PHP_VERSIONS; do
  for SAPI in cli fpm; do
    CONF_DIR="/etc/php/${VERSION}/${SAPI}/conf.d"

    if [ -d "$CONF_DIR" ]; then
      sudo ln -sf /opt/php-conf/common.ini \
        "$CONF_DIR/99-omni-common.ini"

      if [ -f /opt/php-conf/dev.ini ]; then
        sudo ln -sf /opt/php-conf/dev.ini \
          "$CONF_DIR/99-omni-dev.ini"
      fi

      if [ -f /opt/php-conf/xdebug.ini ]; then
        sudo cp -f /opt/php-conf/xdebug.ini \
          "$CONF_DIR/99-omni-xdebug.ini" && \
        sudo sed -i "s|9000|90$(echo $VERSION | tr -d .)|g" \
          "$CONF_DIR/99-omni-xdebug.ini"
      fi
    fi
  done
done


echo "[start] Starting PHP-FPM services..."

for VERSION in $PHP_VERSIONS; do
  if command -v php-fpm${VERSION} &>/dev/null; then
    sudo sed -i "s|listen = /run/php/php${VERSION}-fpm.sock|listen = 90$(echo $VERSION | tr -d .)|g" \
      /etc/php/${VERSION}/fpm/pool.d/www.conf 2>/dev/null || true && \
    sudo sed -i \
      -e 's/^user = www-data$/user = omni/' \
      -e 's/^group = www-data$/group = omni/' \
      -e 's/^listen.owner = www-data$/listen.owner = omni/' \
      -e 's/^listen.group = www-data$/listen.group = omni/' \
      /etc/php/${VERSION}/fpm/pool.d/www.conf 2>/dev/null || true && \
    sudo php-fpm${VERSION} --nodaemonize &
    echo "[start] php-fpm${VERSION} started at socket 90$(echo $VERSION | tr -d .)"
  fi
done

echo "[start] workspace-php ready"
echo "[start] Default PHP: $(php -v | head -1)"
echo "[start] Node: $(node -v)"
echo "[start] pnpm: $(pnpm -v)"

exec tail -f /dev/null
