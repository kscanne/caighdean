#!/bin/bash
if [ $# -ge 2 ]
then
	echo "Usage: bash work.sh [-d|-x]"
	exit 1
fi
# tweakable parameters...
WORDSTODO=185
FROMAMONG=185
AFTERSKIPPING=0
# 1 means keep upper and lower; 0 means just lower
CAPITALS_P=1

#### start of main ####
TEANGA=""
CLAR="qo"
if [ $# -eq 1 ]
then
	if [ "${1}" = "-x" ]
	then
		TEANGA="-gv"
		CLAR="gv"
	else
		if [ "${1}" = "-d" ]
		then
			TEANGA="-gd"
			CLAR="gd"
		else
			echo "Usage: bash work.sh [-d|-x]"
			exit 1
		fi
	fi
fi
FILTER="[@]"
if [ $CAPITALS_P -eq 0 ]
then
	FILTER="[A-Z]"
fi
cat unknown${TEANGA}.txt | sed 's/^[0-9]* //' | sed "1,${AFTERSKIPPING}d" | egrep '..' | egrep -v "$FILTER" | head -n ${FROMAMONG} | shuf | head -n ${WORDSTODO} | sort -u |
while read x
do
	echo
	echo
	echo "-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-"
	echo "Á LORG: $x"
	$CLAR "$x"
done | more
