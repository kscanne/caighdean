#!/bin/bash
if [ $# -ne 1 ]
then
	echo "Usage: bash fulltest.sh [-a|-r]"
	echo "-a: Run all tests"
	echo "-r: Reset test output"
	exit 1
fi

FREAMH=${HOME}/seal/caighdean
TMPFILE=`mktemp`
cd ${FREAMH}
cat test/tokentest-in.txt | perl preproc.pl | perl alltokens.pl "-‐" "0-9ʼ’'#_@" > $TMPFILE
if [ "${1}" = "-r" ]
then
	cp -f $TMPFILE test/tokentest-out.txt
else  # -a case (default)
	diff -u test/tokentest-out.txt $TMPFILE
fi
eval "rm -f $TMPFILE; exit $?"
