#!/bin/bash
# naively tokenize ASCII and unicode apostrophes as boundary chars;
# normalize to ASCII in caighdean.pl
# and keep as boundary chars only for words appearing in lexicon
FREAMH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd ${FREAMH}
perl preproc.pl | bash alltokens.sh | perl nasc.pl $@ | perl caighdean.pl $@
