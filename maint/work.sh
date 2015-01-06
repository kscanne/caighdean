#!/bin/bash
# $ cd ..
# $ make maint/unknown-gd.txt
# $ cd maint
# $ cat unknown-gd.txt | egrep -v '^[0-4] ' | sed 's/^[0-9]* //' | egrep '...' | egrep -v '_' | sort -u > cands.txt
cat cands.txt |
while read x
do
	echo
	echo
	echo "-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-"
	echo "Á LORG: $x"
	gd "$x"
done | more
