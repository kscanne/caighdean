CORPUS=corpus.txt
# The code in this directory is designed to set up the Redis database
# that stores the Irish language n-gram model used by caighdean
# The targets toward the bottom of this file are for KPS; others
# could in principle drop a plain text corpus file in this directory,
# change the CORPUS variable above, and do "make" to generate your own model

# probably want to wipe existing redis DB before doing this:
# $ redis-cli
# > flushall
# > info keyspace
# > quit
#  And then watch DigitalOcean console to check memory usage...
# Topped out at 84% for the build I did on new borel 23 July 2023.
# That was 125M word corpus, 42M unique trigrams before pruning, ~20 min total!
# Previous run before moregan fix was ~2 hrs on 16 March 2016
# with about 95M word corpus, 31M unique trigrams
redis-refresh: training-1.txt training-2.txt training-3.txt buildmodel.pl
	perl buildmodel.pl 3

training-1.txt : alltokens.txt
	cat alltokens.txt | egrep -v '^\\n$$' | LC_ALL=C sort | LC_ALL=C uniq -c | LC_ALL=C sort -r -n | sed 's/^ *//' > $@

training-2.txt : alltokens.txt
	cat alltokens.txt | egrep -v '^\\n$$' | perl ngramify.pl 2 | LC_ALL=C sort | LC_ALL=C uniq -c | LC_ALL=C sort -r -n | sed 's/^ *//' > $@

training-3.txt : alltokens.txt
	cat alltokens.txt | egrep -v '^\\n$$' | perl ngramify.pl 3 | LC_ALL=C sort | LC_ALL=C uniq -c | LC_ALL=C sort -r -n | sed 's/^ *//' > $@

training-4.txt : alltokens.txt
	cat alltokens.txt | egrep -v '^\\n$$' | perl ngramify.pl 4 | LC_ALL=C sort | LC_ALL=C uniq -c | LC_ALL=C sort -r -n | sed 's/^ *//' > $@

# note we're not using caighdean tokenizer, QUITE ON PURPOSE
# cleanup.sh now (re-)normalizes unicode apostrophes and hyphens,
# so enough to tokenize with ASCII ' and - only
# also note that since we're trying to build a STANDARD language model
# we don't even bother tokenizing leading/trailing apostrophes
# we DO want to keep the range of characters roughly in parallel with
# what's in caighdean/alltokens.sh
# Markup killed in cleanup.sh by gaeilgeamhain.pl so no need for special catchall tag
# The normalizations to <URI>, etc. should stay in sync with
# the ngram_preprocess function in caighdean/caighdean.pl
alltokens.txt: $(CORPUS) cleanup.sh ../alltokens.pl
	cat $(CORPUS) | bash cleanup.sh | perl ../alltokens.pl "'-" "0-9#_@" | perl denoise.pl -v | perl tolow.pl | sed 's/^[0-9][0-9,.:]*$$/<NUM>/' | sed '/:\/\//s/^.*$$/<URI>/' | sed '/.\{70\}/s/.*/<LONG>/' | sed 's/^@[A-Za-z0-9_][A-Za-z0-9_]*$$/<USER>/' | sed 's/^[A-Za-z0-9].*@.*$$/<EMAIL>/' > $@

# like alltokens but where I don't want to shuffle source text sentences!
alltokens-order.txt: corpus-pre.txt cleanup.sh ../alltokens.pl
	cat corpus-pre.txt | egrep '[.?!"”]$$' | bash cleanup.sh | perl ../alltokens.pl "'-" "0-9#_@" | perl denoise.pl -v | perl tolow.pl | sed 's/^[0-9][0-9,.:]*$$/<NUM>/' | sed '/:\/\//s/^.*$$/<URI>/' | sed '/.\{70\}/s/.*/<LONG>/' | sed 's/^@[A-Za-z0-9_][A-Za-z0-9_]*$$/<USER>/' | sed 's/^[A-Za-z0-9].*@.*$$/<EMAIL>/' > $@

#######################################
## Targets below are for KPS only!!  ##
#######################################
DIOLAIM=${HOME}/gaeilge/diolaim
CRUB=/usr/local/share/crubadan/ga
OKCHARS=A-ZÁÉÍÓÚa-záéíóú

# these three targets do the cleaning: filters applied from faster to slower
# egrep '[.?!"]$$' is powerful but really cuts down - less than 60% of total
# Then tried doing the egrep '[.?!"]$$', but also keep the others,
# only after running sort -u though, to wipe out repeated boilerplate:
# (LC_ALL=C sort -u corpus-pre.txt | egrep -v '[.?!"]$$'; egrep '[.?!"]$$' corpus-pre.txt) > $@
# Finally, settled on just doing sort -u!
corpus.txt: corpus-pre.txt
	LC_ALL=C sort -u corpus-pre.txt | randomize > $@

# add in a random sample of this size; probably want to keep it
# around max 10% of total number of sentences?
TWEETS=500000
ITSONRAI=${HOME}/gaeilge/crubadan/twitter/sonrai
# model for standard Irish so don't worry about normalizing apostrophes like
# 'un, 'sé, a', srl.
# I used to do discard English (filt.pl -v en) here, but since that discards
# stuff with URLs and might keep other langs, I wrote a gaeilgeamhain.pl
# to only keep stuff that's mostly Irish
corpus-pre.txt: corpus-pre-pre.txt
	(cat $(ITSONRAI)/ga-tweets.txt | randomize | sed 's/^[0-9]*\t[0-9]*\t//' | egrep -v '^RT' | head -n $(TWEETS) | de-entify; cat corpus-pre-pre.txt) | clean-sent.pl '$(OKCHARS)' | sed "s/\([A-ZÁÉÍÓÚa-záéíóú]\)[’ʼ]\([A-ZÁÉÍÓÚa-záéíóú]\)/\1'\2/g" | sed "s/[‑‐−]/-/g" | perl gaeilgeamhain.pl > $@

# beginning is like "cat okdocs.txt | xargs cat" but adds a space
# at start of each file so abairti-dumb won't run sentences together
# from separate files
# Important that everything in corpus is valid UTF-8 before piping
# through all of this; grep will choke on binary files and even
# stops abruptly when encountering invalid characters
corpus-pre-pre.txt: okdocs.txt
	cat okdocs.txt | while read fn; do sed '1s/^/\n/' "$$fn" | abairti-dumb | tr "\000-\011" " " | tr "\013-\037" " " | sed 's/   */ /g' | egrep -v '.{500}' | egrep '.{20}'; done > $@

# Filtering: (1) sites that make it into corpus some other way, e.g.
# Indigenous Tweets, *.blogspot.*, Tuairisc, Wikipedia, etc.
# and also anything pre-standard (CELT, corkirish, wikisource, etc.)
# Stuff in latter category should be copied to diolaim/sean if possible...
webonly.txt:
	cat $(CRUB)/MANIFEST | sed '1d' | egrep -v '(blogspot.com|corkirish|indigenoustweets|smo.uhi.ac.uk|wikipedia|wikisource.org|ucc.ie/celt|celt.ucc.ie)' | sed 's@^[^ ]* @$(CRUB)/ciu/@' > $@
	(cd ${HOME}/seal/irishcompleted/walescrawler; make > /dev/null 2>&1; cat okdocs.txt) >> $@
	echo '/home/kps/seal/irishcompleted/leipzig/gle_mixed_unique.txt' >> $@
	echo '/home/kps/seal/irishcompleted/oscar/ga_dedup-scag.txt' >> $@
	echo '/home/kps/seal/irishcompleted/biobla/bible.com/OC70' >> $@
	echo '/home/kps/seal/irishcompleted/biobla/bible.com/OF81' >> $@
	echo '/home/kps/seal/irishcompleted/NCE/nce.txt' >> $@
	echo '/home/kps/seal/irishcompleted/gaois/gaois.txt' >> $@

# Adding OF81 back in 18 Jul 2016; => webonly.txt (bible.com) above 06 Jan 2020
# IB-laighneach == t/OB36 == ria/AU021
localonly.txt:
	(find $(DIOLAIM)/l -type f | egrep -v '(Twitter|TA|IB-laighneach)'; find $(DIOLAIM)/n $(DIOLAIM)/r -type f) > $@

okdocs.txt: webonly.txt localonly.txt
	cat webonly.txt localonly.txt | sed '/\.swp$$/d' > $@

clean:
	rm -f okdocs.txt corpus.txt alltokens.txt corpus-pre.txt corpus-pre-pre.txt training*.txt webonly.txt localonly.txt
