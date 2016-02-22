#!/bin/bash
FREAMH=${HOME}/seal/caighdean
TMPFILE=`mktemp`
cd ${FREAMH}
cat test/detokentest-in.txt | perl alltokens.pl "-‐" "0-9ʼ’'#_@" | perl detokenize.pl > $TMPFILE
diff -u test/detokentest-in.txt $TMPFILE
eval "rm -f $TMPFILE; exit $?"
