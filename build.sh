#!/usr/bin/env bash

# https://vaneyckt.io/posts/safer_bash_scripts_with_set_euxo_pipefail/
set -euxo pipefail

ROC="roc"

# generate templates
rm -rf src/Views/Pages.roc
rtl -e "html" -i ./templates/ -o ./src/Views/ || true # currently a workaround for not being able to roc check from a parent
(ls ./src/Views/Pages.roc >> /dev/null 2>&1 && exit)
cd ./src/Views && $ROC check Pages.roc && cd ../..

# build app
rm -rf src/app
# $ROC build --optimize app.roc || true
$ROC build src/app.roc || true
(ls src/app >> /dev/null 2>&1 && exit)

# build css
rm -rf www/app.css
# tailwindcss -i site.css -o www/app.css --minify
tailwindcss -i site.css -o www/app.css

# clean test sqlite db
rm -rf app.db
sqlite3 app.db < app.sql

# start server
cd www
(trap 'kill 0' SIGINT; ../src/app & simple-http-server --port 8001 --cors)
