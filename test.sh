#!/bin/bash
#
. ./instabug-env.sh

REQ_URL="https://dashboard-api.instabug.com/api/web/applications/io-l-app-dei-servizi-pubblici/beta/rules/1019532"
curl --silent --request GET --header "Authorization: Token token=${USER_TOKEN}, email=${USER_EMAIL}" "$REQ_URL"

### END-OF-SCRIPT
