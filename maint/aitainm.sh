#!/bin/bash
# Country names, etc.; candidates for addition to multi-gd.txt
egrep '^[A-Z].* an t?[A-Z][^ ]+$' ../pairs-gd.txt |
while read x
do
	echo "$x" | sed 's/^/le_/; s/ an / leis an /'
	echo "$x" | sed 's/^/ri_/; s/ an / leis an /'
	echo "$x" | sed 's/^/gu_/; s/ an / go dtí an /'
	echo "$x" | sed 's/^/à_/; s/ an / as an /'
	echo "$x" | sed 's/^/bho_/; s/ an / ón /'
	echo "$x" | sed 's/^/o_/; s/ an / ón /'
	echo "$x" | sed 's/^/de_/; s/ an / den /'
	echo "$x" | sed 's/^/do_/; s/ an / don /'
	echo "$x" | sed 's/^/ann_an_/; s/^ann_an_\([BFMP]\)/ann_am_\1/; s/ an \([AEIOUÁÉÍÓÚ]\|Fh[aeiouáéíóú]\)/ san \1/; s/ an / sa /'
done | keepif -n ../multi-gd.txt
