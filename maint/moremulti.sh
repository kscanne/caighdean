#!/bin/bash
# Look for stuff in pairs-gd.txt with a hyphen on gd side
# that makes sense for multi-gd.txt too...
FREQDIR=${HOME}/seal/idirlamha/gd/freq
TMP1=`mktemp`
TMP2=`mktemp`
cat ${FREQDIR}/bigrams.txt | sed 's/^[0-9]* //' > ${TMP1}
cat ../multi-gd.txt | sed 's/ .*//' | sed 's/_/ /g' > ${TMP2}
egrep -h '^[^ -][^ -][^ -]+-[^ -][^ -][^ -]+ ' ../pairs*-gd.txt | sed 's/ .*//' | sort -u | sed 's/-/ /' | egrep -v ' (aon|ris|san|tha|uair)$' | keepif ${TMP1} | keepif -n ${TMP2} | sed 's/ /-/' |
while read x
do
	egrep -h "^$x " ../pairs*-gd.txt
done | sed 's/-/_/'
rm -f ${TMP1} ${TMP2}
