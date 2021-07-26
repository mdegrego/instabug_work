#!/bin/bash
#
# daily_counts.sh / v1.063 / Linux version
# last updated: Rome, 2021 July 9th
# authors: MdG

cycle_days() {

  CATEGORY_LABEL=$1
  CATEGORY=$2
  SUBTOTAL=0
  CSV_BUFFER=${CSV_BUFFER}$'\n'${CATEGORY_LABEL}

  if [ "$NO_PROMPT" == 0 ]; then printf "\n--- ${CATEGORY_LABEL}\n"; fi

  CURRENT_DATE=${BEGIN_DATE}
  while [ "${CURRENT_DATE}" != "${END_DATE}" ]; do

    DATE_FROM=$(date -d "${CURRENT_DATE} 00:00:00 UTC+02" "+%s")
    DATE_TO=$(date -d "${CURRENT_DATE} 23:59:59 UTC+02" "+%s")
    DATE_FROM=${DATE_FROM}"000"
    DATE_TO=${DATE_TO}"999"

    API_OUT=$(curl --silent --location --request GET \
    "https://dashboard-api.instabug.com/api/web/applications/io-l-app-dei-servizi-pubblici/beta/bugs?direction=desc&filters=%7B%22category%22:%5B%5B%22${CATEGORY}%22%5D%5D,%22reported_at%22:%7B%22from%22:${DATE_FROM},%22to%22:${DATE_TO}%7D%7D" \
    --header "Authorization: Token token=${USER_TOKEN}, email=${USER_EMAIL}" | jq -r ".count")

    if [ "$NO_PROMPT" == 0 ]; then printf "${CURRENT_DATE} segnalazioni = ${API_OUT}\n"; fi
    CSV_BUFFER=${CSV_BUFFER}","${API_OUT}

    SUBTOTAL=$((${SUBTOTAL} + ${API_OUT}))
    CURRENT_DATE=$(date -d "${CURRENT_DATE} +1 day" +%Y-%m-%d)
  done

  SUMMARY=${SUMMARY}${CATEGORY_LABEL}": "${SUBTOTAL}"\n"
  TOTAL=$((${TOTAL} + ${SUBTOTAL}))
}

#############
### ENTRY ###
#############

DIR=$(cd "$(dirname "$0")"; pwd)
cd "${DIR}"
. ./instabug-env.sh

NO_PROMPT=0
NO_CSV=0
if [[ $# -eq 1 && "$1" == "-nocsv" ]]; then
  NO_CSV=1
elif [[ $# -eq 1 && "$1" == "-noprompt" ]]; then
  NO_PROMPT=1
  NO_CSV=1
fi

if [ "$NO_PROMPT" == 0 ]; then
  printf "\n***************** PagoPA app IO L2 Support *****************"
  printf "\n*****************      daily_counts        *****************\n"
  printf "\ninserisci '1' per specificare una data SINGOLA"
  printf "\ninserisci '2' per specificare un RANGE di date\n"
fi

if [ "$NO_PROMPT" == 1 ]; then
  KEY=1
else
  read KEY
fi

if [ "$KEY" == '1' ]; then

  if [ "$NO_PROMPT" == 0 ]; then
    printf "\nspecifica la data nel formato AAAA-MM-GG [INVIO vuoto = OGGI]: "
    read BEGIN_DATE
  fi
  if [ "$BEGIN_DATE" == '' ]; then
    BEGIN_DATE=$(date +%Y-%m-%d)
  fi
  END_DATE=$(date -d "${BEGIN_DATE} +1 day" +%Y-%m-%d)

elif [ "$KEY" == '2' ]; then

  printf "\nspecifica data inizio, nel formato AAAA-MM-GG: "
  read BEGIN_DATE
  printf "specifica data fine, nel formato AAAA-MM-GG: "
  read END_DATE
  END_DATE=$(date -d "${END_DATE} +1 day" +%Y-%m-%d)

else
  
  printf "\nopzione non valida, uscita."
  sleep 1
  exit 0
  
fi

TOTAL=0
SUMMARY="--- Totali per ciascuna categoria ---\n\n"

# CSV: generate the first row

CSV_BUFFER="giorno"
CURRENT_DATE=${BEGIN_DATE}
while [ "${CURRENT_DATE}" != "${END_DATE}" ]; do
  CSV_BUFFER=${CSV_BUFFER}","${CURRENT_DATE}
  CURRENT_DATE=$(date -d "${CURRENT_DATE} +1 day" +%Y-%m-%d)
done

# cycle_days(): first param  = A friendly-name for Category (label)
#               second param = Internal name for Category used by the API calls

cycle_days 'Accesso tramite SPID' 'Accesso+tramite+SPID'
cycle_days 'Accesso tramite CIE' 'Accesso+tramite+CIE'
cycle_days 'Cashback > IBAN' 'IBAN'
cycle_days 'Cashback > Metodo Pagamento' 'Metodo+pagamento'
cycle_days 'Cashback > Transazioni' 'Transazioni'
cycle_days 'Bonus Vacanze' 'Bonus+Vacanze'
cycle_days 'Pagamento pagoPA' 'Pagamento+pagoPA'
cycle_days 'Certificazione Verde COVID-19 > Informazioni generali' 'Informazioni+generali'
cycle_days 'Certificazione Verde COVID-19 > Non ho ricevuto nulla' 'Non+ho+ricevuto+nulla'
cycle_days 'Certificazione Verde COVID-19 > Problemi tecnici su IO' 'Problemi+tecnici+su+IO'
cycle_days 'Accessibilità \ Usabilità' 'Accessibilità+\\+Usabilità'

printf "\n\n${SUMMARY}"
printf "\nTOTAL: ${TOTAL}\n\n"

# Store CSV file in the current directory

if [ "$NO_CSV" != 1 ]
then
  CSV_FILENAME="daily_counts_$(date +%Y%m%d_%s).csv"
  echo "${CSV_BUFFER}" | ruby -rcsv -e 'puts CSV.parse(STDIN).transpose.map &:to_csv' > ${CSV_FILENAME}
  printf "File CSV generato al path: ${PWD}/${CSV_FILENAME}"
fi

if [ "$NO_PROMPT" == 0 ]; then
  printf "\nPress any key to exit...\n"
  read -n 1 -s KEY
fi
exit 0

### END-OF-SCRIPT
