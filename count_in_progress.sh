#!/bin/bash
#
# count_in_progress.sh / v2.00 / Linux version
# last updated: Rome, 2021 Jul 29
# authors: MdG
#
# Cosa fa questo script: conta tutti i bug che soddisfano
#
# PRIORITY = ANY
# ASSIGNEE = ANY
# STATUS = "In progress"

DIR=$(cd "$(dirname "$0")"; pwd)
cd "${DIR}"
. ./instabug-env.sh

BEGIN_DATE=$(date +%Y-%m-%d -d "13 days ago")
END_DATE=$(date +%Y-%m-%d -d "+1 day")
IN_PRGS_TOTAL=0
CURRENT_DATE=${BEGIN_DATE}

while [ "${CURRENT_DATE}" != "${END_DATE}" ]; do

  DATE_FROM=$(date -d "${CURRENT_DATE} 00:00:00 UTC+02" "+%s")
  DATE_TO=$(date -d "${CURRENT_DATE} 23:59:59 UTC+02" "+%s")
  DATE_FROM=${DATE_FROM}"000"
  DATE_TO=${DATE_TO}"999"

  API_OUT=$(curl --silent --location --request GET \
  "https://dashboard-api.instabug.com/api/web/applications/io-l-app-dei-servizi-pubblici/beta/bugs?direction=asc&filters=%7B%22status_id%22:%5B3%5D,%22reported_at%22:%7B%22from%22:${DATE_FROM},%22to%22:${DATE_TO}%7D%7D" \
  --header "Authorization: Token token=${USER_TOKEN}, email=${USER_EMAIL}" | jq -r ".count")

  printf "\n%s In-Progress: %s" ${CURRENT_DATE} ${API_OUT}
  IN_PRGS_TOTAL=$((${IN_PRGS_TOTAL} + ${API_OUT}))
  CURRENT_DATE=$(date -d "${CURRENT_DATE} +1 day" +%Y-%m-%d)

done

printf "\n\nIn-Progress TOTAL: %s\n" ${IN_PRGS_TOTAL}

### END-OF-SCRIPT
