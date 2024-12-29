#!/usr/bin/env bash

# This script is used to build and run the app locally.

# https://vaneyckt.io/posts/safer_bash_scripts_with_set_euxo_pipefail/
set -euxo pipefail

# generate templates
# NOTE THIS IS TEMPORARILY DISABLED
# rtl -e "html" -i ./templates/ -o ./src/Views/

# build app
roc build src/main.roc --output src/server

# build css
tailwindcss -i site.css -o www/app.css

# clean test sqlite db
rm -rf app.db && sqlite3 app.db < app.sql

# start server
DB_PATH=app.db \
STATIC_FILES=www/ \
ROC_BASIC_WEBSERVER_HOST=127.0.0.1 \
ROC_BASIC_WEBSERVER_PORT=8001 \
src/server
