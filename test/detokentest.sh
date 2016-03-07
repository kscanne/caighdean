#!/bin/bash
FREAMH=${HOME}/seal/caighdean
TMPFILE=`mktemp`
TMPFILE2=`mktemp`
cd ${FREAMH}
# monolingual detokenization, roundtrip
cat test/detokentest-in.txt | bash alltokens.sh | perl detokenize.pl > $TMPFILE
# bilingual detokenization
cat test/testin.txt | bash tiomanai.sh | perl detokenize.pl > $TMPFILE2
diff -u test/detokentest-in.txt $TMPFILE && diff -u test/detokentest-eid.txt $TMPFILE2
eval "rm -f $TMPFILE $TMPFILE2; exit $?"
