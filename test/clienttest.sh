#!/bin/bash
FREAMH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/.."

# first arg is file extension for test file
# second arg is tmp filename containing (precomputed) tiomanai.sh output
# third arg is name of language interpreter (bash, python, perl, ...)
# fourth arg is source language code (ga, gd, or gv)
testoneclient() {
	EXTENSION=`echo "${3}" | sed 's/^bash$/.sh/; s/^perl$/.pl/; s/^python$/.py/; s/^ruby$/.rb/'`
	TMPFILE2=`mktemp`
	cat "test/testin${1}.txt" | ${3} "clients/client${EXTENSION}" ${4} > $TMPFILE2
	diff -u "${2}" "${TMPFILE2}"
	# eval ensures $? will contain exit val of the diff
	eval "rm -f $TMPFILE2; return $?"
}

# first arg is file extension for test file
# second arg is flag passed to tiomanai.sh
# third arg is source language code (ga, gd, or gv)
testonelang() {
	TMPFILE=`mktemp`
	cat "test/testin${1}.txt" | bash tiomanai.sh ${2} > $TMPFILE
	testoneclient "${1}" "$TMPFILE" 'bash' "${3}" && testoneclient "${1}" "$TMPFILE" 'perl' "${3}" && testoneclient "${1}" "$TMPFILE" 'python' "${3}" && testoneclient "${1}" "$TMPFILE" 'ruby' "${3}" && testoneclient "${1}" "$TMPFILE" '' "${3}"
	eval "rm -f $TMPFILE; return $?"
}

cd ${FREAMH}
(cd clients; make &> /dev/null)
# will short-circuit if any one fails
testonelang '' '' 'ga' && testonelang '-gd' '-d' 'gd' && testonelang '-gv' '-x' 'gv'
