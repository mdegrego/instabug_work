#!/bin/bash
#
# block_inactive_bugs.sh / v2.05 / Linux version
# last updated: Rome, 2021 Feb 16
# authors: MdG
#
# Cosa fa questo script: cerca tutti i bug che soddisfano
#
# PRIORITY = NOT "Blocker"
# ASSIGNEE = "N/A"
# REPORTED AT = "fino a 14 giorni prima"
#
# e per ciascuno si imposta
#
# 1.PRIORITY = "Blocker"
# 2.STATUS = "Closed"
# 3.Post messaggio di chiusura (file: closing-msg.txt)

post_message() {

  BUG_NUMBER=$1
  TMPAUX=$2
  LOGFILE=$3

  curl \
    --silent \
    --location \
    --request GET \
    'https://dashboard-api.instabug.com/api/web/applications/io-l-app-dei-servizi-pubblici/beta/bugs/'${BUG_NUMBER} \
    --header "Authorization: Token token=${USER_TOKEN}, email=${USER_EMAIL}" > ${TMPAUX}

  CHAT_NUMBER=$(jq -r ".bug.chat_number" ${TMPAUX})

  curl --silent -X POST -H "Content-Type: multipart/form-data; boundary=----WebKitFormBoundaryU0KDqCvKphclST6c" --data-binary @closing-msg.txt \
    'https://dashboard-api.instabug.com/api/web/applications/io-l-app-dei-servizi-pubblici/beta/chats/'${CHAT_NUMBER}'/messages' \
    --header "Authorization: Token token=${USER_TOKEN}, email=${USER_EMAIL}" > /dev/null

  LOGLINE=">>> Recovering chat number for Bug# "$BUG_NUMBER"\n>>> Posting to chat# "$CHAT_NUMBER
  echo -e ${LOGLINE} 2>&1 | tee -a ${LOGFILE}
  rm ${TMPAUX}
}

### ENTRY ###

DIR=$(cd "$(dirname "$0")"; pwd)
cd "${DIR}"
. ./instabug-env.sh

NO_PROMPT=0
if [[ $# -eq 1 && "$1" == "-noprompt" ]]; then
  NO_PROMPT=1
elif [[ $# -eq 3 && "$1" == "-range" ]]; then
  TXT_DATE_FROM=$2
  TXT_DATE_TO=$3
  NO_PROMPT=2
fi

echo -e "\n***************** PagoPA  app IO L2 Support ******************"
echo -e "***************** block_inactive_bugs v2.05 ******************\n"

DEFAULT_DATE_FROM=$(date +%Y-%m-%d -d "90 days ago")
DEFAULT_DATE_TO=$(date +%Y-%m-%d -d "14 days ago")

echo "--- il campo d'azione si restringe alle segnalazioni aperte in un dato RANGE DI DATE (reported_at):"
echo "specifica data INIZIO nel formato AAAA-MM-GG [INVIO vuoto = 90 giorni fa = ${DEFAULT_DATE_FROM}]"
if [ "$NO_PROMPT" == 0 ]; then read TXT_DATE_FROM; fi
if [ "$TXT_DATE_FROM" == '' ]; then
  TXT_DATE_FROM=$DEFAULT_DATE_FROM
fi

echo "specifica data FINE nel formato AAAA-MM-GG [INVIO vuoto = 14 giorni fa = ${DEFAULT_DATE_TO}]"
if [ "$NO_PROMPT" == 0 ]; then read TXT_DATE_TO; fi
if [ "$TXT_DATE_TO" == '' ]; then
  TXT_DATE_TO=$DEFAULT_DATE_TO
fi

NOW=$(date +%s)
LOG_FILENAME="block_inactive_bugs_${TXT_DATE_FROM}-${TXT_DATE_TO}___${NOW}.log"
TMP_FILENAME="tmp_${TXT_DATE_FROM}-${TXT_DATE_TO}___${NOW}.json"
TMPAUX_FILENAME="tmpaux_${TXT_DATE_FROM}-${TXT_DATE_TO}___${NOW}.json"

DATE_FROM=$(date -d "${TXT_DATE_FROM} 00:00:00 UTC+02" "+%s")
DATE_TO=$(date -d "${TXT_DATE_TO} 23:59:59 UTC+02" "+%s")
DATE_FROM=${DATE_FROM}"000"
DATE_TO=${DATE_TO}"999"

# query result ordering: ascending/oldest "asc" or descending/newer "desc"
DIRECTION="asc"

REQ_URL="https://dashboard-api.instabug.com/api/web/applications/io-l-app-dei-servizi-pubblici/beta/bugs?\
direction=${DIRECTION}&\
filters=%7B\
%22priority_id%22:%5B-1,1,2,3%5D,\
%22assignee_id%22:%5B-1%5D,\
%22reported_at%22:%7B%22from%22:${DATE_FROM},%22to%22:${DATE_TO}%7D%7D"

curl --silent --location --header "Authorization: Token token=${USER_TOKEN}, email=${USER_EMAIL}" --request GET "$REQ_URL" > ${TMP_FILENAME}

N_BUGS=$(jq -r ".count" ${TMP_FILENAME})
N_PAGES_float=$(echo ${N_BUGS}/20 | bc -l)
N_PAGES=${N_PAGES_float%.*}

echo -e "--- riepilogo query ---\n    ASSIGNEE = N/A\n    PRIORITY = NOT Blocker\n    REPORTED_AT = [${TXT_DATE_FROM}, ${TXT_DATE_TO}]"
echo "--- tot. segnalazioni: "${N_BUGS}
echo "--- max pagine (da 20): "${N_PAGES}
echo
if [ "$N_BUGS" == 0 ]; then
  rm ${TMP_FILENAME}
  exit 0
fi

echo "Press any key to start (q to exit)..."
echo
if [ "$NO_PROMPT" != 1 ]; then
  read -n 1 -s KEY
  if [ "$KEY" == 'q' ]; then
    rm ${TMP_FILENAME}
    exit 0
  fi
fi

BLOCKED=0
PAGE_INDEX=0

for i in $(seq 1 $N_PAGES);
do
  PCT_float=$(echo "scale=2; "$PAGE_INDEX*100/$N_BUGS | bc -l)
  REPORTED_AT=$(jq -r ".bugs[0].reported_at" ${TMP_FILENAME} | tr -d '\n')

  LOG_ENTRY="--- page no. "$i" reported_at: "${REPORTED_AT}" --- segnalazioni processate: "$PAGE_INDEX" ("$PCT_float"%)"
  echo ${LOG_ENTRY} 2>&1 | tee -a ${LOG_FILENAME}

  for (( j=0 ; ; j++ ))
  do
    BUG_ID=$(jq -r ".bugs[$j].number" ${TMP_FILENAME} | tr -d '\n')
    CHAT_ID=$(jq -r ".bugs[$j].chat_number" ${TMP_FILENAME} | tr -d '\n')
    if [ "$BUG_ID" == "null" ] || [ ${#BUG_ID} == 0 ]; then
      break
    fi

    # set to Blocker
    curl --silent -X POST -H "Content-Type: application/json" -d '{"value":4}' \
    'https://dashboard-api.instabug.com/api/web/applications/io-l-app-dei-servizi-pubblici/beta/bugs/'${BUG_ID}'/change_priority' \
    --header "Authorization: Token token=${USER_TOKEN}, email=${USER_EMAIL}" > /dev/null

    # set to Closed
    curl --silent -X POST -H "Content-Type: application/json" -d '{"value":2}' \
    'https://dashboard-api.instabug.com/api/web/applications/io-l-app-dei-servizi-pubblici/beta/bugs/'${BUG_ID}'/change_status' \
    --header "Authorization: Token token=${USER_TOKEN}, email=${USER_EMAIL}" > /dev/null

    LOG_ENTRY="bug# "$BUG_ID" chat# "$CHAT_ID" >>> BLOCKED & NOTIFIED USER <<<"
    echo ${LOG_ENTRY} 2>&1 | tee -a ${LOG_FILENAME}

    # notify user
    if [ "$CHAT_ID" != 0 ]; then
      curl --silent -X POST -H "Content-Type: multipart/form-data; boundary=----WebKitFormBoundaryU0KDqCvKphclST6c" --data-binary @closing-msg.txt \
        'https://dashboard-api.instabug.com/api/web/applications/io-l-app-dei-servizi-pubblici/beta/chats/'${CHAT_ID}'/messages' \
        --header "Authorization: Token token=${USER_TOKEN}, email=${USER_EMAIL}" > /dev/null
    else
      # for some reason the chat id is not available from the list, so let's try a recovery procedure
      post_message $BUG_ID $TMPAUX_FILENAME $LOG_FILENAME
    fi

    BLOCKED=$((1+${BLOCKED}))
  done

  # load next page

  PAGE_INDEX=$((20+${PAGE_INDEX}))
  curl --silent --location --header "Authorization: Token token=${USER_TOKEN}, email=${USER_EMAIL}" \
    --request GET "${REQ_URL}&pagination_token=${PAGE_INDEX}" > ${TMP_FILENAME}
done

LOG_ENTRY="\n--- SUMMARY ---\n\n--- REPORTED_AT = ["${TXT_DATE_FROM}", "${TXT_DATE_TO}"]\n--- segnalazioni = "${N_BUGS}"\n--- segnalazioni BLOCKED = "${BLOCKED}"\n\n---------------------------------------------------------------\n"
echo -e ${LOG_ENTRY} 2>&1 | tee -a ${LOG_FILENAME}
rm ${TMP_FILENAME}

if [[ ${BLOCKED} -eq 0 ]]; then
  exit 0
else
  exit 5
fi

### END-OF-SCRIPT
