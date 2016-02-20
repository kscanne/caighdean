#!/bin/bash
FREAMH=${HOME}/seal/caighdean
! egrep -v '^[^ _]+(_[^ _]+)+ ([^_]*[^_ ])$' ${FREAMH}/multi*.txt && ! egrep -v '^[^ _]+ ([^ _]+)( [^ _]+)*$' ${FREAMH}/pairs*.txt ${FREAMH}/spurious*.txt && ! egrep '[ʼ’]' ${FREAMH}/multi*.txt ${FREAMH}/spurious*.txt ${FREAMH}/pairs*.txt
