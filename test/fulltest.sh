#!/bin/bash
FREAMH=${HOME}/seal/caighdean

testone() {
	TMPFILE=`mktemp`
	(cd ..; cat "test/testin${2}.txt" | bash tiomanai.sh ${3} | sed 's/^.* => //' | perl detokenize.pl > $TMPFILE)
	if [ "${1}" = "-r" ]
	then
		cp -f $TMPFILE "testout${2}.txt"
	else  # -a case (default)
		diff -u "testout${2}.txt" $TMPFILE
	fi
	# eval ensures $? will contain exit val of the diff
	eval "rm -f $TMPFILE; return $?"
}

if [ $# -ne 1 ]
then
	echo "Usage: bash fulltest.sh [-a|-r]"
	echo "-a: Run all tests"
	echo "-r: Reset test output"
	exit 1
fi

cd ${FREAMH}/test
# will short-circuit if any one fails
testone "${1}" '' '' && testone "${1}" '-gd' '-d' && testone "${1}" '-gv' '-x'
