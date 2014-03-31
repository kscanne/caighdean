#!/bin/bash
# naively tokenize ASCII and unicode apostrophes as boundary chars;
# normalize to ASCII in caighdean.pl
# and keep as boundary chars only for words appearing in lexicon
perl alltokens.pl "-‐" "0-9’'#@" | perl nasc.pl $@ | perl caighdean.pl $@
