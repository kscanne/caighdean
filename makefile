# These two files make up the test set
# Typical workflow: tweak code or input files, evaluate with
# $ make ok.txt
# and then examine errors with 
# $ vimdiff pre-tokens.txt post-tokens.txt
# LHS = gold-standard, RHS = output of caighdeánaitheoir
TESTPRE=testpre.txt
TESTPOST=testpost.txt
TESTSIZE=500

all: ok.txt

# only if copyrighted material is added en masse
shuffle: FORCE
	paste testpre.txt testpost.txt | shuf | tee pasted.txt | cut -f 1 > newpre.txt
	cat pasted.txt | cut -f 2 > testpost.txt
	mv -f newpre.txt testpre.txt
	rm -f pasted.txt

# evaluate the algorithm that does nothing to the prestandard text!
baseline: FORCE
	@perl compare.pl $(TESTPOST) $(TESTPRE)
	@echo `cat unchanged.txt | wc -l` "out of" `cat $(TESTPRE) | wc -l` "unchanged"
	@echo "Baseline got these right, we got them wrong:"
	@cat unchanged.txt | keepif -n ok.txt

testpre-beag.txt: $(TESTPRE)
	cat $(TESTPRE) | head -n $(TESTSIZE) > $@

testpost-beag.txt: $(TESTPOST)
	cat $(TESTPOST) | head -n $(TESTSIZE) > $@

# run pre-standardized text through the new code
tokenized-output.txt: testpre-beag.txt tiomanai.sh caighdean.pl rules.txt clean.txt pairs.txt ngrams.txt alltokens.pl pairs-local.txt spurious.txt
	cat testpre-beag.txt | bash tiomanai.sh > $@

nua-output.txt: tokenized-output.txt detokenize.pl
	cat tokenized-output.txt | sed 's/^.* => //' | perl detokenize.pl > $@

# compare.pl outputs unchanged.txt (set of sentences from
# testpost.txt that we got right),
# pre-tokens.txt (correct standardizations in sentences we got wrong),
# and post-tokens.txt (the standardizations we output)
ok.txt: nua-output.txt testpost-beag.txt compare.pl
	perl compare.pl testpost-beag.txt nua-output.txt
	echo `cat unchanged.txt | wc -l` "out of" `cat nua-output.txt | wc -l` "correct"
	mv unchanged.txt ok.txt
	git diff ok.txt

# TODO: Add an independent test of detokenizer; use generic
# modern texts, not stuff from CCGB that may have already by detokenized once

eid-output.txt: tokenized-output.txt
	cat tokenized-output.txt | perl detokenize.pl > $@

clean:
	rm -f detokentest.txt unchanged.txt post-tokens.txt pre-tokens.txt tokenized-output.txt nua-output.txt cga-output.txt testpre-beag.txt testpost-beag.txt

############## COMPARISON WITH RULE-BASED VERSION ONLY ###############

cga-output.txt: tokenized-output.txt
	cat testpre-beag.txt | cga > $@

cgaeval: cga-output.txt FORCE
	perl compare.pl testpost-beag.txt cga-output.txt
	echo `cat unchanged.txt | wc -l` "out of" `cat cga-output.txt | wc -l` "correct"

############## TARGETS FOR MAINTAINER ONLY ! ###############
GAELSPELL=${HOME}/gaeilge/ispell/ispell-gaeilge
CRUB=/usr/local/share/crubadan

refresh: rules.txt clean.txt pairs.txt ngrams.txt

pairs.txt: $(GAELSPELL)/apost $(GAELSPELL)/gaelu $(GAELSPELL)/athfhocail $(GAELSPELL)/earraidi
	LC_ALL=C sort -u $(GAELSPELL)/apost $(GAELSPELL)/gaelu $(GAELSPELL)/athfhocail $(GAELSPELL)/earraidi | sort -k1,1 > $@
	chmod 444 $@

#ngrams.txt: ${HOME}/gaeilge/ngram/ga-model.txt
#	cp -f ${HOME}/gaeilge/ngram/ga-model.txt $@
#	chmod 444 $@

# GLAN==aspell.txt, LEXICON=GLAN + proper names, etc.
# ispell personal, uimhreacha, apost; .ispell_gaeilge; dinneenok.txt
clean.txt: $(CRUB)/ga/LEXICON
	cp -f $(CRUB)/ga/LEXICON $@
	chmod 444 $@

rules.txt: ${HOME}/gaeilge/gramadoir/gr/ga/morph-ga.txt
	cat ${HOME}/gaeilge/gramadoir/gr/ga/morph-ga.txt | iconv -f iso-8859-1 -t utf8 | egrep -v '^#' | sed 's/^\([^ \t]*\)[ \t]*\([^ \t]*\)[ \t]*\([^ \t]*\).*/\1\t\2\t\3/' > $@
	chmod 444 $@

maintainer-clean:
	$(MAKE) clean
	rm -f rules.txt clean.txt pairs.txt ngrams.txt alltokens.pl

FORCE:
