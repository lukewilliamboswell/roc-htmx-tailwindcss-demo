#!/usr/bin/env bash

# https://vaneyckt.io/posts/safer_bash_scripts_with_set_euxo_pipefail/
set -euxo pipefail

ROC="roc"

# generate templates
rm -rf Generated/
mkdir Generated
rtl -e "html" -i ./templates -o ./Generated || true # currently a workaround for not being able to roc check from a parent
(ls ./Generated/Pages.roc >> /dev/null 2>&1 && exit)
cd ./Generated && $ROC check Pages.roc && cd ..

# build app
rm -rf app
# $ROC build --optimize app.roc || true
$ROC build app.roc || true
(ls app >> /dev/null 2>&1 && exit)

# build css
rm -rf www/app.css
tailwindcss -i site.css -o www/app.css --minify

cd www

# start server
(trap 'kill 0' SIGINT; ../app & simple-http-server --port 8001 --cors)
