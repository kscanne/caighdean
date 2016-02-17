#!/bin/bash
if [ $# -ge 2 ]
then
	echo "Usage: bash work.sh [-d|-x]"
	exit 1
fi
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
BARR=20
cat unknown${TEANGA}.txt | sed 's/^[0-9]* //' | egrep '..' | egrep -v '_' | head -n ${BARR} | sort -u |
while read x
do
	echo
	echo
	echo "-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-"
	echo "Á LORG: $x"
	$CLAR "$x"
done
