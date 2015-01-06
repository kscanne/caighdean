if [ $# -ne 2 ]
then
	echo "Usage: bash eval.sh FILE1 FILE2"
	exit 1
fi
TMP1=`mktemp`
TMP2=`mktemp`
cat "${1}" | perl ../alltokens.pl "-‐" "0-9ʼ’'#@" | egrep -v '^(<[^>]+>|\\n)$' | egrep '[A-Za-záéíóúÁÉÍÓÚàèìòùÀÈÌÒÙ]' > $TMP1
cat "${2}" | perl ../alltokens.pl "-‐" "0-9ʼ’'#@" | egrep -v '^(<[^>]+>|\\n)$' |
 egrep '[A-Za-záéíóúÁÉÍÓÚàèìòùÀÈÌÒÙ]' > $TMP2
perl wer.pl "${TMP1}" "${TMP2}"
rm -f $TMP1 $TMP2
