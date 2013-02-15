#!/bin/bash
#perl alltokens.pl "'-" "0-9" | egrep -v '^\\n$' | perl caighdean.pl
perl alltokens.pl "-" "0-9'" | perl caighdean.pl
