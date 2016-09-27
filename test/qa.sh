#!/bin/bash
FREAMH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/.."
! egrep -v '^[^ _]+(_[^ _]+)+ ([^_]*[^_ ])$' ${FREAMH}/multi*.txt && ! egrep -v '^[^ _]+ ([^ _]+)( [^ _]+)*$' ${FREAMH}/pairs*.txt ${FREAMH}/spurious*.txt && ! egrep '[ʼ’\\]' ${FREAMH}/multi*.txt ${FREAMH}/spurious*.txt ${FREAMH}/pairs*.txt && ! egrep "^([BDMTbdmt]|[Dd]h)'_[^_]+$" ${FREAMH}/multi*.txt
