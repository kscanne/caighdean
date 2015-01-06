#!/bin/bash
egrep -v '^[^ _]+(_[^ _]+)+ ([^_]+)$' ../multi*.txt
egrep -v '^[^ _]+ ([^ _]+)( [^ _]+)*$' ../pairs*.txt ../spurious*.txt
