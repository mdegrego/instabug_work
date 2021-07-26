#!/bin/bash
#
# open-so-far / v1.0 / Linux version
# last updated: Rome, 2021 Feb 17
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

NOW=$(date +%T)
NOW_EP=$(date +%s)
TMP_FILENAME="tmp_open-so-far___${NOW_EP}.txt"

echo "NUOVI BUG ENTRATI OGGI (fino ad ora)" > ${TMP_FILENAME}
./daily_counts-v1.063-gnu.sh -noprompt >> ${TMP_FILENAME}
echo "DISTRIBUZIONE DELLE IN-PROGRESS (nelle ultime 2 settimane)" >> ${TMP_FILENAME}
./count_in_progress.sh >> ${TMP_FILENAME}

cat ./${TMP_FILENAME} | mail -s "Report segnalazioni ($NOW)" ${SLACK_EMAIL}
rm ${TMP_FILENAME}

### END-OF-SCRIPT
