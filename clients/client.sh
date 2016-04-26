#/bin/bash
if [ $# -ne 1 ]
then
	echo "Usage: $ bash client.sh [ga|gd|gv]\n"
	exit 1
fi
# the 'echo x' bit allows us to preserve a trailing newline in input
SLURP=`cat; echo x`
curl -s https://borel.slu.edu/cgi-bin/seirbhis3.cgi --data foinse="${1}" --data-urlencode teacs="${SLURP%x}" | sed 's/^\[//; s/\]$/\n/' | sed 's/\],\[/]\n[/g' | sed 's/^\["\(..*\)","\(..*\)"\]/\1 => \2/' | sed 's/\\\(.\)/\1/g'
