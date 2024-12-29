#!/usr/bin/env bash

# This script is used to build and run the app locally.

# https://vaneyckt.io/posts/safer_bash_scripts_with_set_euxo_pipefail/
set -euxo pipefail

# generate templates
# NOTE THIS IS TEMPORARILY DISABLED
# It generates Views/Pages.roc ok, but fails when `roc check`ing the file. So I've just
# checked the Pages file in for now.
#
# Restore after https://github.com/roc-lang/roc/issues/7429
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
