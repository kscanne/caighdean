#!/bin/bash
FREAMH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/.."
TMPFILE=`mktemp`
TMPFILE2=`mktemp`
TMPFILE3=`mktemp`
cd ${FREAMH}
# monolingual detokenization, roundtrip
cat test/detokentest-in.txt | bash alltokens.sh | sed 's/^.*$/& => &/' | perl detokenize.pl -s > $TMPFILE
cat test/detokentest-in.txt | bash alltokens.sh | sed 's/^.*$/& => &/' | perl detokenize.pl -t > $TMPFILE2
# bilingual detokenization, NEID format
cat test/testin.txt | bash tiomanai.sh | perl detokenize.pl -f > $TMPFILE3
diff -u test/detokentest-in.txt $TMPFILE && diff -u test/detokentest-in.txt $TMPFILE2 && diff -u test/detokentest-eid.txt $TMPFILE3
eval "rm -f $TMPFILE $TMPFILE2 $TMPFILE3; exit $?"
