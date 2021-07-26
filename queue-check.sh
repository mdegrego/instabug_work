#!/bin/bash
#
# check-queue / v1.0 / Linux version
# last updated: Rome, 2021 Feb 23
# authors: MdG

DIR=$(cd "$(dirname "$0")"; pwd)
cd "${DIR}"
. ./instabug-env.sh

NOW=$(date +%T)
NOW_EP=$(date +%s)
TMP_FILENAME="tmp_check-queue___${NOW_EP}.txt"

REQ_URL="https://dashboard-api.instabug.com/api/web/applications/io-l-app-dei-servizi-pubblici/beta/rules/1019532"
STATUS1=$(curl --silent --request GET --header "Authorization: Token token=${USER_TOKEN}, email=${USER_EMAIL}" "$REQ_URL" | jq -r ".conditions.list[0].operator")
REQ_URL="https://dashboard-api.instabug.com/api/web/applications/io-l-app-dei-servizi-pubblici/beta/rules/1018623"
STATUS2=$(curl --silent --request GET --header "Authorization: Token token=${USER_TOKEN}, email=${USER_EMAIL}" "$REQ_URL" | jq -r ".conditions.list[0].operator")

if [[ "$STATUS1" == 1 && "$STATUS2" == 1 ]]
then
  echo "Coda APERTA" > ${TMP_FILENAME}
else
  echo "Coda CHIUSA!" > ${TMP_FILENAME}
fi

./count_in_progress.sh >> ${TMP_FILENAME}

cat ./${TMP_FILENAME} | mail -s "Stato coda ($NOW)" ${SLACK_EMAIL}
rm ${TMP_FILENAME}

### END-OF-SCRIPT
