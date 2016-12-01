#!/bin/bash
FREAMH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/.."

generictest() {
	TMPFILE=`mktemp`
	cd ${FREAMH}
	cat test/nasctest-in.txt | bash alltokens.sh | perl nasc.pl > $TMPFILE
	if [ "${1}" = "-r" ]
	then
		cp -f $TMPFILE test/nasctest-out.txt
	else  # -a case (default)
		diff -u test/nasctest-out.txt $TMPFILE
	fi
	# eval ensures $? will contain exit val of the diff
	eval "rm -f $TMPFILE; return $?"
}

# tokenize LHS's of multi file, run through nasc.pl and should get 
# the same thing back...
trivialtest() {
	TMPFILE=`mktemp`
	cd ${FREAMH}
	cat multi${1}.txt | sed 's/ .*//' > $TMPFILE
	# without inserted commas, possible for MWEs to "interfere"
	# e.g. "ny_slooid ny_slooid_ny" => "ny_slooid_ny slooid ny"
	cat multi${1}.txt | sed 's/ .*/\n,/' | tr "\n" " " | tr '_' ' ' | bash alltokens.sh | perl nasc.pl ${2} | egrep -v '^,$' | diff -u $TMPFILE -
	eval "rm -f $TMPFILE; return $?"
}

if [ $# -ne 1 ]
then
	echo "Usage: bash nasctest.sh [-a|-r]"
	echo "-a: Run all tests"
	echo "-r: Reset test output"
	exit 1
fi

if [ "${1}" = "-r" ]
then
	generictest -r
else
	generictest -a && trivialtest '' '' && trivialtest '-gd' '-d' && trivialtest '-gv' '-x'
fi
