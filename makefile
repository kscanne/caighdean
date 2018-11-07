# These two files make up the test set
# Typical workflow: tweak code or input files, evaluate with
# $ make ok.txt
# and then examine errors with 
# $ diff -u pre-tokens.txt post-tokens.txt
# or visually with 
# $ make surv
# LHS = gold-standard, RHS = output of caighdeánaitheoir
TESTPRE=eval/testpre.txt
TESTPOST=eval/testpost.txt
TESTGDGA=eval/testpost-gd.txt
TESTGD=eval/testpre-gd.txt
TESTGVGA=eval/testpost-gv.txt
TESTGV=eval/testpre-gv.txt

all: ok.txt

install: cands.hash cands-gd.hash cands-gv.hash

cands.hash: spurious.txt clean.txt pairs.txt pairs-local.txt multi.txt
	perl hashbuild.pl

cands-gd.hash: spurious-gd.txt clean.txt pairs-gd.txt pairs-local-gd.txt multi-gd.txt
	perl hashbuild.pl -d

cands-gv.hash: spurious-gv.txt clean.txt pairs-gv.txt pairs-local-gv.txt multi-gv.txt
	perl hashbuild.pl -x

######################  TARGETS FOR TESTING   ###########################
test: FORCE
	! perl caighdean.pl -t | egrep '^not ok'
	bash test/qa.sh
	bash test/tokentest.sh -a
	bash test/nasctest.sh -a
	bash test/detokentest.sh
	bash test/fulltest.sh -a
	bash test/clienttest.sh

commitlog: FORCE
	git add maint/oov.txt maint/oov-gd.txt maint/oov-gv.txt eval/speedlog.txt eval/wer.txt eval/wer-gd.txt eval/wer-gv.txt
	git commit -m "Latest OOV and WER numbers"

###################### TARGETS FOR EVALUATION ###########################
# evaluate the algorithm that does nothing to the prestandard text!
baseline: FORCE
	@perl compare.pl $(TESTPOST) $(TESTPRE)
	@echo `cat unchanged.txt | wc -l` "out of" `cat $(TESTPRE) | wc -l` "unchanged"
	@(cd eval; bash baseline.sh)

baseline-gd: FORCE
	@perl compare.pl $(TESTGDGA) $(TESTGD)
	@echo `cat unchanged.txt | wc -l` "out of" `cat $(TESTGD) | wc -l` "unchanged"
	@(cd eval; bash baseline.sh -d)

baseline-gv: FORCE
	@perl compare.pl $(TESTGVGA) $(TESTGV)
	@echo `cat unchanged.txt | wc -l` "out of" `cat $(TESTGV) | wc -l` "unchanged"
	@(cd eval; bash baseline.sh -x)

# run pre-standardized text through the new code
tokenized-output.txt: $(TESTPRE) tiomanai.sh nasc.pl caighdean.pl rules.txt clean.txt pairs.txt alltokens.sh alltokens.pl pairs-local.txt spurious.txt multi.txt
	cat $(TESTPRE) | bash tiomanai.sh > $@

tokenized-output-gd.txt: $(TESTGD) tiomanai.sh nasc.pl caighdean.pl rules-gd.txt clean.txt pairs-gd.txt alltokens.sh alltokens.pl pairs-local-gd.txt spurious-gd.txt multi-gd.txt
	cat $(TESTGD) | bash tiomanai.sh -d > $@

tokenized-output-gv.txt: $(TESTGV) tiomanai.sh nasc.pl caighdean.pl rules-gv.txt clean.txt pairs-gv.txt alltokens.sh alltokens.pl pairs-local-gv.txt spurious-gv.txt multi-gv.txt
	cat $(TESTGV) | bash tiomanai.sh -x > $@

nua-output.txt: tokenized-output.txt detokenize.pl
	cat tokenized-output.txt | perl detokenize.pl -t > $@

nua-output-gd.txt: tokenized-output-gd.txt detokenize.pl
	cat tokenized-output-gd.txt | perl detokenize.pl -t > $@

nua-output-gv.txt: tokenized-output-gv.txt detokenize.pl
	cat tokenized-output-gv.txt | perl detokenize.pl -t > $@

# doing full files is too slow
surv: FORCE
	head -n 10000 pre-tokens.txt > pre-surv.txt
	head -n 10000 post-tokens.txt > post-surv.txt
	vimdiff pre-surv.txt post-surv.txt

# compare.pl outputs unchanged.txt (set of sentences from
# testpost.txt that we got right),
# pre-tokens.txt (correct standardizations in sentences we got wrong),
# and post-tokens.txt (the standardizations we output)
ok.txt: nua-output.txt $(TESTPOST) compare.pl
	perl compare.pl $(TESTPOST) nua-output.txt
	echo `cat unchanged.txt | wc -l` "out of" `cat nua-output.txt | wc -l` "correct"
	mv unchanged.txt $@
	git diff $@

ok-gd.txt: nua-output-gd.txt $(TESTGDGA) compare.pl
	perl compare.pl $(TESTGDGA) nua-output-gd.txt
	echo `cat unchanged.txt | wc -l` "out of" `cat nua-output-gd.txt | wc -l` "correct"
	mv unchanged.txt $@
	git diff $@

ok-gv.txt: nua-output-gv.txt $(TESTGVGA) compare.pl
	perl compare.pl $(TESTGVGA) nua-output-gv.txt
	echo `cat unchanged.txt | wc -l` "out of" `cat nua-output-gv.txt | wc -l` "correct"
	mv unchanged.txt $@
	git diff $@

speedeval: FORCE
	bash eval/speedeval.sh
	bash eval/speedeval.sh -d
	bash eval/speedeval.sh -x

eid-output.txt: tokenized-output.txt
	cat tokenized-output.txt | perl detokenize.pl -f > $@

# running this *and* make clean in model/ returns to a clean clone of the repo
# *except* for the files eval/testp*.txt which are not tracked so we never
# clean them up here or anywhere else (i.e. this target is perfectly safe)
clean:
	rm -f *.hash unchanged.txt post-tokens.txt pre-tokens.txt tokenized-output*.txt nua-output*.txt cga-output.txt pre-surv.txt post-surv.txt eid-output.txt maint/tofixgram.txt maint/modern-unknown.txt maint/unknown*.txt maint/grammar*.txt clients/client

############## Build test sets from parallel corpora ###############
#              should never need to run these again!               #
####################################################################

# just LM019 has numbered lines
ccnua-refresh: FORCE
	find ${HOME}/gaeilge/caighdean/traenail -type f -name '*-b' | sed 's/-b$$//' | while read x; do paste $$x $$x-b | sed 's/^[^:]*: *//' | sed 's/\t[^:]*: */\t/'; done | shuf | tee pasted.txt | cut -f 1 > $(TESTPOST)
	cat pasted.txt | cut -f 2 > $(TESTPRE)
	rm -f pasted.txt

# only directly-translated material
ccgg-refresh: FORCE
	find ${HOME}/gaeilge/ga2gd/ccgg -type f | egrep -v -- '-b$$' | egrep '/(Aghaidh|AnGuth1|AnMaor|Bean|Briseadh|Ceacht|ceangalg|cluaisean|Coimhthioch|colmcille|Comhra|Ecstasy|Feoil|Healy|Hurlamaboc|LaNaSaboide|leathchead|MacM|maifia|Malairt|NaFocail|OsComhair|Punk|Ronan|Sean|slicholmcille|Somhairle|WP)$$' | while read x; do paste $$x $$x-b | sed 's/^[^:]*: *//' | sed 's/\t[^:]*: */\t/'; done | shuf | tee pasted.txt | cut -f 1 > $(TESTGDGA)
	cat pasted.txt | cut -f 2 > $(TESTGD)
	rm -f pasted.txt

# only directly-translated material
cc-refresh: FORCE
	find ${HOME}/gaeilge/ga2gv/cc -type f | egrep -v -- '-b$$' | egrep '/(AnBB|Ecstasy|Fainne|Healy|Paloma|Reics|Teifeach)$$' | while read x; do paste $$x $$x-b | sed 's/^[^ ]*: *//' | sed 's/\t[^ ]*: */\t/'; done | shuf | tee pasted.txt | cut -f 1 > $(TESTGVGA)
	cat pasted.txt | cut -f 2 > $(TESTGV)
	rm -f pasted.txt

# only if copyrighted material is added en masse
shuffle: FORCE
	paste $(TESTPRE) $(TESTPOST) | shuf | tee pasted.txt | cut -f 1 > newpre.txt
	cat pasted.txt | cut -f 2 > $(TESTPOST)
	mv -f newpre.txt $(TESTPRE)
	rm -f pasted.txt

############## COMPARISON WITH RULE-BASED VERSION ONLY ###############

cga-output.txt: tokenized-output.txt
	cat $(TESTPRE) | cga > $@

cgaeval: cga-output.txt FORCE
	perl compare.pl $(TESTPOST) cga-output.txt
	echo `cat unchanged.txt | wc -l` "out of" `cat cga-output.txt | wc -l` "correct"

############## MAINTENANCE TARGETS: SURVEY OF UNKNOWN WORDS, ETC #############
SEANCHORPAS=${HOME}/gaeilge/caighdean/prestandard/corpus.txt
SEANTOKENS=${HOME}/gaeilge/caighdean/prestandard/alltokens.txt
maint/unknown.txt: $(SEANCHORPAS) multi.txt pairs.txt pairs-local.txt rules.txt spurious.txt alltokens.sh alltokens.pl nasc.pl tiomanai.sh
	cat $(SEANCHORPAS) | bash tiomanai.sh -u | egrep '[A-Za-zÁÉÍÓÚáéíóúÀÈÌÒÙàèìòù]' | egrep -v '^[:;]' | LC_ALL=C egrep -v '^@[A-Za-z0-9_]+$$' | sort | uniq -c | sort -r -n | sed 's/^ *//' > $@

maint/oov.txt: maint/unknown.txt $(SEANCHORPAS) alltokens.sh alltokens.pl nasc.pl
	echo `date '+%Y-%m-%d %H:%M:%S'` `(cat maint/unknown.txt | sed 's/ .*//' | addem; echo '10000'; echo '*'; cat $(SEANTOKENS) | egrep -v '^[<\\]' | wc -l; echo '/'; echo 'p') | dc | sed 's/..$$/.&/'` >> $@
	tail $@

GDCORPUS=${HOME}/seal/idirlamha/gd/freq/corpus.txt
GDTOKENS=${HOME}/seal/idirlamha/gd/freq/alltokens.txt
maint/unknown-gd.txt: $(GDCORPUS) multi-gd.txt pairs-gd.txt pairs-local-gd.txt rules-gd.txt spurious-gd.txt alltokens.sh alltokens.pl nasc.pl tiomanai.sh
	cat $(GDCORPUS) | bash tiomanai.sh -d -u | egrep '[A-Za-zÁÉÍÓÚáéíóúÀÈÌÒÙàèìòù]' | egrep -v '^[:;]' | LC_ALL=C egrep -v '^@[A-Za-z0-9_]+$$' | sort | uniq -c | sort -r -n | sed 's/^ *//' > $@

maint/oov-gd.txt: maint/unknown-gd.txt $(GDCORPUS) alltokens.sh alltokens.pl nasc.pl
	echo `date '+%Y-%m-%d %H:%M:%S'` `(cat maint/unknown-gd.txt | sed 's/ .*//' | addem; echo '10000'; echo '*'; cat $(GDTOKENS) | egrep -v '^[<\\]' | wc -l; echo '/'; echo 'p') | dc | sed 's/..$$/.&/'` >> $@
	tail $@

GVCORPUS=${HOME}/seal/idirlamha/gv/freq/corpus.txt
GVTOKENS=${HOME}/seal/idirlamha/gv/freq/alltokens.txt
maint/unknown-gv.txt: $(GVCORPUS) multi-gv.txt pairs-gv.txt pairs-local-gv.txt rules-gv.txt spurious-gv.txt alltokens.sh alltokens.pl nasc.pl tiomanai.sh
	cat $(GVCORPUS) | bash tiomanai.sh -x -u | egrep '[A-Za-zçÇÁÉÍÓÚáéíóúÀÈÌÒÙàèìòù]' | egrep -v '^[:;]' | LC_ALL=C egrep -v '^@[A-Za-z0-9_]+$$' | sort | uniq -c | sort -r -n | sed 's/^ *//' > $@

maint/oov-gv.txt: maint/unknown-gv.txt $(GVCORPUS) alltokens.sh alltokens.pl nasc.pl
	echo `date '+%Y-%m-%d %H:%M:%S'` `(cat maint/unknown-gv.txt | sed 's/ .*//' | addem; echo '10000'; echo '*'; cat $(GVTOKENS) | egrep -v '^[<\\]' | wc -l; echo '/'; echo 'p') | dc | sed 's/..$$/.&/'` >> $@
	tail $@

# grammar check standardizer output, to catch stuff
# like "go dtáinig", "i n-áit" and so on that we didn't fix...
# often these arise because they appear frequently in n-gram model -
# add them to cleanup.sh in that dir
# NB... doing this on parallel corpus, but could actually
# run any texts at all (e.g. GDCORPUS, GVCORPUS above)
# through and grammar check the output
maint/grammar.txt: nua-output.txt
	cat nua-output.txt | commonerrs > $@

maint/grammar-gd.txt: nua-output-gd.txt
	cat nua-output-gd.txt | commonerrs > $@

maint/grammar-gv.txt: nua-output-gv.txt
	cat nua-output-gv.txt | commonerrs > $@

# in testpost.txt; use this output to further standardize testpost.txt manually
# standardizer only... doesn't really make sense for gd2ga/gv2ga
maint/tofixgram.txt: FORCE
	cat $(TESTPOST) | commonerrs > $@

maint/modern-unknown.txt maint/modern-tokens.txt: FORCE
	cat model/corpus.txt | randomize | head -n 1000000 > maint/temp-mod-corp.txt
	cat maint/temp-mod-corp.txt | perl preproc.pl | bash alltokens.sh | egrep -v '^\\n' | wc -l > maint/modern-tokens.txt
	cat maint/temp-mod-corp.txt | bash tiomanai.sh -u | egrep '[A-Za-zÁÉÍÓÚáéíóú]' | egrep -v '[@#]' | egrep -v '://' | sort | uniq -c | sort -r -n | sed 's/^ *//' > maint/modern-unknown.txt
	echo `date '+%Y-%m-%d %H:%M:%S'` `(cat maint/modern-unknown.txt | sed 's/ .*//' | addem; echo '10000'; echo '*'; cat maint/modern-tokens.txt; echo '/'; echo 'p') | dc | sed 's/..$$/.&/'` >> maint/oov-modern.txt
	rm -f maint/temp-mod-corp.txt
	tail maint/oov-modern.txt

############## TARGETS FOR MAINTAINER ONLY ! ###############
GAELSPELL=${HOME}/gaeilge/ispell/ispell-gaeilge
PRESTD=${HOME}/gaeilge/caighdean/prestandard
CRUBLOCAL=${HOME}/gaeilge/crubadan/crubadan
GRAMADOIR=${HOME}/gaeilge/gramadoir/gr/ga
CRUB=/usr/local/share/crubadan
GA2GD=${HOME}/gaeilge/ga2gd/ga2gd
GA2GV=${HOME}/gaeilge/ga2gv/ga2gv

# rules.txt currently locally modified - don't refresh from gramadoir!
# do "make refresh" right after running "groom"
refresh: clean.txt-refresh pairs.txt-refresh alltokens.pl-refresh ngramify.pl-refresh

# make groom called in ~/clar/script/groom, which is called from "cdup"
groom: pairs.txt-refresh clean.txt-refresh rules.txt-refresh
	cat multi.txt | LC_ALL=C sort -u | LC_ALL=C sort -k1,1 > temp.txt
	if ! diff -q temp.txt multi.txt; then cp -f temp.txt multi.txt; fi
	rm -f temp.txt
	make cands.hash

# removed gaelu for RIA May 2014; doesn't make sense if trying to mimic
# a human standardizing a pre-standard Irish book for example
pairs.txt-refresh: $(GAELSPELL)/apost $(GAELSPELL)/athfhocail $(GAELSPELL)/earraidi $(PRESTD)/immutable.txt
	(cat $(PRESTD)/immutable.txt | sed 's/^.*$$/& &/'; cat $(GAELSPELL)/apost $(GAELSPELL)/athfhocail $(GAELSPELL)/earraidi) | LC_ALL=C sort -u | sort -k1,1 > temp.txt
	if ! diff -q temp.txt pairs.txt; then cp -f temp.txt pairs.txt; chmod 444 pairs.txt; fi
	rm -f temp.txt

# actually updates pairs-gd.txt and multi-gd.txt
# the make target in $(GA2GD) copies pairs-gd.txt back here
# but don't delete multi-gd.txt below: it just adds new pairs to what's here
pairs-gd.txt-refresh: FORCE
	rm -f pairs-gd.txt
	(cd $(GA2GD); make pairs-gd.txt)
	chmod 444 pairs-gd.txt

# see comments above for gd
pairs-gv.txt-refresh: FORCE
	rm -f pairs-gv.txt
	(cd $(GA2GV); make pairs-gv.txt)
	chmod 444 pairs-gv.txt

# run groom to rebuild caighdean.txt if necessary
clean.txt-refresh: FORCE
	if ! diff -q $(GAELSPELL)/caighdean.txt clean.txt; then cp -f $(GAELSPELL)/caighdean.txt clean.txt; chmod 444 clean.txt; fi

rules.txt-refresh: $(GRAMADOIR)/morph-ga.txt
	cat $(GRAMADOIR)/morph-ga.txt | iconv -f iso-8859-1 -t utf8 | sed '/SYNTHETIC FORMS/,/END PREFIX STRIPPING/s/^/#/' | sed '/start emphatic/,/end emphatic/s/^/#/' | sed '/start derivational/,/end derivational/s/^/#/' | sed '/DEMUTATE/,$$s/^/#/' | sed '/^\^do(/,/^\^h?in(\[\^/s/^/#/' | sed '/^fa\?ir/s/idh/idh_tú/' | sed '/rules-local.txt here/r rules-local.txt' | sed '/^[^#]/s/^\([^ \t]*\)[ \t]*\([^ \t]*\)[ \t]*\([^ \t]*\).*/\1\t\2\t\3/' > temprules.txt
	if ! diff -q temprules.txt rules.txt; then cp -f temprules.txt rules.txt; chmod 444 rules.txt; fi
	rm -f temprules.txt

alltokens.pl-refresh: $(CRUBLOCAL)/alltokens.pl
	rm -f alltokens.pl
	cp $(CRUBLOCAL)/alltokens.pl alltokens.pl
	chmod 444 alltokens.pl

ngramify.pl-refresh: $(CRUBLOCAL)/ngramify.pl
	rm -f model/ngramify.pl
	cp $(CRUBLOCAL)/ngramify.pl model/ngramify.pl
	chmod 444 model/ngramify.pl

# don't wipe rules.txt - locally modified
maintainer-clean:
	$(MAKE) clean
	rm -f clean.txt pairs.txt ngrams.txt alltokens.pl

FORCE:
