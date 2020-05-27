#!/bin/bash

# odstraní starý adresář pro deploy
rm -rf ./deploy
# vytvoří nový adresá řpro deploy
mkdir ./deploy
# zkopíruje všechny zdrojové adresáře a soubory
echo "Copying folders and files..."
cp -r ./bin ./deploy/bin
cp -r ./tests ./deploy/tests
cp -r ./config ./deploy/config
cp -r ./public ./deploy/public
cp -r ./src ./deploy/src
cp -r ./templates ./deploy/templates
cp ./composer.json ./deploy/composer.json
cp ./index.html ./deploy/index.html
cp ./LICENSE.md ./deploy/LICENSE.md
cp ./README.md ./deploy/README.md
cp ./.htaccess ./deploy/.htaccess
cp ./.env ./deploy/.env
cp ./.env.dev ./deploy/.env.dev
cp ./.env.prod ./deploy/.env.prod
rm -r ./deploy/public/develop
rm -r ./deploy/src/DataFixtures

# generates a production file with global settings
composer dump-env dev
cp ./.env.local.php ./deploy/.env.dev.php
composer dump-env prod
cp ./.env.local.php ./deploy/.env.local.php
rm ./.env.local.php

# shellcheck disable=SC2164
cd ./deploy

# installs production packages
composer install

php ./bin/phpunit install

php ./bin/console lint:twig templates --env=dev --show-deprecations --no-interaction
php ./bin/console lint:yaml config --env=dev --parse-tags --no-interaction
php ./bin/console lint:yaml translations --env=dev --no-interaction --parse-tags
php ./bin/console lint:xliff translations --env=dev --no-interaction
php ./bin/console lint:container --env=dev --no-interaction
php ./bin/console security:check
php ./bin/console doctrine:schema:validate --skip-sync -vvv --no-interaction
php ./bin/phpunit

rm -r ./var
rm -r ./vendor

composer install --no-dev --optimize-autoloader --classmap-authoritative --no-interaction
APP_ENV=prod APP_DEBUG=0 php ./bin/console cache:clear
php ./bin/console lint:twig templates --env=prod --no-debug --show-deprecations --no-interaction
php ./bin/console lint:yaml config --env=prod --no-debug --parse-tags --no-interaction
php ./bin/console lint:yaml translations --env=prod --no-debug --no-interaction --parse-tags
php ./bin/console lint:xliff translations --env=prod --no-debug --no-interaction
php ./bin/console lint:container --env=prod --no-debug --no-interaction

rm -r ./var
rm -r ./bin
rm -r ./assets
rm -r ./config/packages/debug
rm -r ./config/packages/dev
rm -r ./config/packages/prew
rm -r ./config/packages/test
rm -r ./config/routes/dev
rm -r ./src/Migrations
rm -r ./tests

rm ./.env
rm ./.env.dev
rm ./.env.prod
rm ./.env.test
rm ./composer.lock
rm ./phpunit.xml.dist
rm ./symfony.lock
rm ./webpack.config.js
rm ./package.json

echo "Zipping the projekt"
zip -r project.zip . $1>/dev/null

echo "Zipping the vendor folder"
zip -r vendor.zip ./vendor $1>/dev/null

