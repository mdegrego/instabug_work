#!/bin/bash
#

DIR=$(cd "$(dirname "$0")"; pwd)
cd "${DIR}"
touch LASTRUN_BEGIN

RUNAGAIN=5
while [ $RUNAGAIN -eq 5 ]
do
  ./block_inactive_bugs-v2.05-gnu.sh -noprompt
  RUNAGAIN=$?
  sleep 30
done

TIMESTAMP=$(date +%Y-%m-%d___%s)
TGZ_FILENAME="block_inactive_bugs_${TIMESTAMP}.tgz"
tar cvfz "${TGZ_FILENAME}" *.log
rm *.log
mv "${TGZ_FILENAME}" logs.archive/
touch LASTRUN_END

echo "<empty>" | mail -s "block_inactive_bugs-v2.05-gnu.sh: COMPLETED <eom>" "marco.degregorio@pagopa.it"
