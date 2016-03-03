#!/bin/bash
FREAMH=${HOME}/seal/caighdean

testonelang() {
	cd ${FREAMH}
	TMPFILE=`mktemp`
	TMPFILE2=`mktemp`
	cat "test/testin-${1}.txt" | bash tiomanai.sh ${2} > $TMPFILE
	cat "test/testin-${1}.txt" | perl clients/client.pl ${1} > $TMPFILE2
	diff -u $TMPFILE $TMPFILE2
	# eval ensures $? will contain exit val of the diff
	eval "rm -f $TMPFILE $TMPFILE2; return $?"
}

# will short-circuit if any one fails
testonelang 'gd' '-d' && testonelang 'gv' '-x'
