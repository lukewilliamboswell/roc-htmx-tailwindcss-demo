#!/usr/bin/env bash

# https://vaneyckt.io/posts/safer_bash_scripts_with_set_euxo_pipefail/
set -euxo pipefail

# generate templates
rm -rf Generated/
mkdir Generated
rtl -i ./templates -o ./Generated || true # currently a workaround for not being able to roc check from a parent
(ls ./Generated/Pages.roc >> /dev/null 2>&1 && exit)
cd ./Generated && roc check Pages.roc && cd ..

# build app
rm -rf app
roc build --optimize app.roc || true
(ls app >> /dev/null 2>&1 && exit)

# build css
rm -rf www/app.css
tailwindcss -i site.css -o www/app.css --minify

cd www

# start server
(trap 'kill 0' SIGINT; ../app & simple-http-server --port 8001 --cors)
