#!/bin/bash
# This script is used throughout this repo for tokenization
# and also in the seal/idirlamha/xx/freq directories...
# If we do change the characters below, should also keep
# the stuff in gaeilge/ngram in sync!
# don't use ${HOME} since web service uses this
FREAMH=/home/kps/seal/caighdean
perl ${FREAMH}/alltokens.pl "-‑‐" "0-9ʼ’'#_@"
