#!/usr/bin/env bash
set -euo pipefail

updated=false
just_cloned=false
if ! [ -e .git ]; then
    echo >&2 "Movim not found in $PWD - cloning now..."
    git clone https://github.com/movim/movim.git .
    current=$(git rev-parse HEAD)
    echo >&2 "Complete! Movim $current cloned successfully to $PWD"
    updated=true
    just_cloned=true
else
    echo >&2 "Movim already exists in $PWD - updating if required..."
    current=$(git rev-parse HEAD)
    git pull --ff-only
    new=$(git rev-parse HEAD)
    if [ $current != $new ]; then
        echo >&2 "Complete! Movim $current updated to $new"
        updated=true
    else
        echo >&2 "Movim $current is already at latest version"
    fi
fi

if [ "$just_cloned" == true ]; then
    echo >&2 "Installing composer..."
    curl -sS https://getcomposer.org/installer | php
fi

if [ "$updated" == true ]; then
    echo >&2 "Installing dependencies..."
    php composer.phar install --optimize-autoloader
fi

cat <<EOT > config/db.inc.php
<?php
\$conf = [
    'type'        => 'pgsql',
    'database'    => '$POSTGRES_DB',
    'host'        => '$POSTGRES_HOST',
    'port'        => '$POSTGRES_PORT',
    'username'    => '$POSTGRES_USER',
    'password'    => '$POSTGRES_PASSWORD',
];
EOT

chown -R www-data:www-data $PWD && chmod -R u+rwx $PWD

php vendor/bin/phinx migrate
php-fpm --daemonize

sleep 5
exec "$@"
