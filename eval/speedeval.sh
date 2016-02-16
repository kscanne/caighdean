#!/bin/bash
# first thousand sentences in each test file, for consistency,
# and since content doesn't really matter
FREAMH=${HOME}/seal/caighdean
SAMPSIZE=1000
if [ $# -ge 2 ]
then
	echo "Usage: bash speedeval.sh [-d|-x]"
	exit 1
fi
TEANGA=""
CLAR="CAIGH"
if [ $# -eq 1 ]
then
	if [ "${1}" = "-x" ]
	then
		TEANGA="-gv"
		CLAR="GV2GA"
	else
		if [ "${1}" = "-d" ]
		then
			TEANGA="-gd"
			CLAR="GD2GA"
		else
			echo "Usage: bash sampeval.sh [-d|-x]"
			exit 1
		fi
	fi
fi
export TIMEFORMAT='%3R'
TMPT=`mktemp`
cd ${FREAMH}
LODAIL=`{ time echo | bash tiomanai.sh $@ > /dev/null 2>&1 ; } 2>&1`
echo `date '+%Y-%m-%d %H:%M:%S'` "${CLAR}" "LOAD" "$LODAIL" >> eval/speedlog.txt
TMPX=`mktemp`
cat eval/testpre${TEANGA}.txt | head -n $SAMPSIZE > $TMPX
PROISEAIL=`{ time cat $TMPX | bash tiomanai.sh $@ > /dev/null 2>&1 ; } 2>&1`
echo `date '+%Y-%m-%d %H:%M:%S'` "${CLAR}" "PROC" "$PROISEAIL" >> eval/speedlog.txt
echo "Speed log:"
tail -n 10 eval/speedlog.txt
rm -f "$TMPX" "$TMPT"
