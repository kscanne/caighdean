#!/bin/bash
FREAMH=${HOME}/seal/caighdean

# first arg the source language code
# second arg is tmp filename containing (precomputed) tiomanai.sh output
# third arg is name of language interpreter (bash, python, perl, ...)
testoneclient() {
	cd ${FREAMH}
	EXTENSION=`echo "${3}" | sed 's/^bash$/sh/; s/^perl$/pl/; s/^python$/py/'`
	TMPFILE2=`mktemp`
	cat "test/testin-${1}.txt" | ${3} "clients/client.${EXTENSION}" ${1} > $TMPFILE2
	diff -u "${2}" "${TMPFILE2}"
	# eval ensures $? will contain exit val of the diff
	eval "rm -f $TMPFILE2; return $?"
}

testonelang() {
	cd ${FREAMH}
	TMPFILE=`mktemp`
	cat "test/testin-${1}.txt" | bash tiomanai.sh ${2} > $TMPFILE
	testoneclient "${1}" "$TMPFILE" 'bash' && testoneclient "${1}" "$TMPFILE" 'perl' && testoneclient "${1}" "$TMPFILE" 'python'
	eval "rm -f $TMPFILE; return $?"
}

# will short-circuit if any one fails
testonelang 'gd' '-d' && testonelang 'gv' '-x'
