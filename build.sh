#!/usr/bin/env bash

# This script is used to build and run the app locally.

# In future I'd love to have a `--watch` command for rtl and basic-webserver
# so we can just have this running in the background and insta load on any changes.
#
# It won't be too hard to implement, it just needs someone to do it.

# https://vaneyckt.io/posts/safer_bash_scripts_with_set_euxo_pipefail/
set -euxo pipefail

ROC="roc"

# generate templates
rtl -e "html" -i ./templates/ -o ./src/Views/

# build app
$ROC build src/app.roc

# build css
tailwindcss -i site.css -o www/app.css

# clean test sqlite db
rm -rf app.db && sqlite3 app.db < app.sql

# start server
# note we do this in a subshell so we can kill both the roc and simple-http-server processes
# with a single ctrl-c, it just makes life easier
cd www
../src/app
