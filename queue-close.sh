#!/bin/bash
#
# close-queue / v1.0 / Linux version
# last updated: Rome, 2021 Feb 23
# authors: MdG

DAY=$(date +%d)
MONTH=$(date +%m)

if [[ $DAY == "01" && $MONTH == "01" || \
      $DAY == "06" && $MONTH == "01" || \
      $DAY == "04" && $MONTH == "04" || \
      $DAY == "05" && $MONTH == "04" || \
      $DAY == "25" && $MONTH == "04" || \
      $DAY == "01" && $MONTH == "05" || \
      $DAY == "02" && $MONTH == "06" || \
      $DAY == "15" && $MONTH == "08" || \
      $DAY == "01" && $MONTH == "11" || \
      $DAY == "08" && $MONTH == "12" || \
      $DAY == "25" && $MONTH == "12" || \
      $DAY == "26" && $MONTH == "12" ]]
then
  exit 0
fi

DIR=$(cd "$(dirname "$0")"; pwd)
cd "${DIR}"
. ./instabug-env.sh

REQ_URL="https://dashboard-api.instabug.com/api/web/applications/io-l-app-dei-servizi-pubblici/beta/rules/1018623"
curl -X PUT -H "Content-Type: application/json" --header "Authorization: Token token=${USER_TOKEN}, email=${USER_EMAIL}" --data @io_non_sono_occupato.json "$REQ_URL"

sleep 1

REQ_URL="https://dashboard-api.instabug.com/api/web/applications/io-l-app-dei-servizi-pubblici/beta/rules/1019532"
curl -X PUT -H "Content-Type: application/json" --header "Authorization: Token token=${USER_TOKEN}, email=${USER_EMAIL}" --data @io_sono_chiuso.json "$REQ_URL"

sleep 10
./queue-check.sh

### END-OF-SCRIPT
