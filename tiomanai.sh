#!/bin/bash
# naively tokenize ASCII and unicode apostrophes as boundary chars;
# normalize to ASCII in caighdean.pl
# and keep as boundary chars only for words appearing in lexicon
perl preproc.pl | bash alltokens.sh | perl nasc.pl $@ | perl caighdean.pl $@
