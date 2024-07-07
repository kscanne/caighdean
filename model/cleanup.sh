#!/bin/bash
perl ../preproc.pl |
sed "s/\([A-ZÁÉÍÓÚa-záéíóú]\)[’ʼ]\([A-ZÁÉÍÓÚa-záéíóú]\)/\1'\2/g" |
sed "s/[‑‐−]/-/g" |
perl gaeilgeamhain.pl |
sed "
s/ ag siúil / ag siúl /gi
s/ fá dear / faoi deara /gi
s/\(^\| \)fá dtaobh /\1fá+dtaobh /gi
s/\(^\| \)fá /\1faoi /gi
s/fá+dtaobh/fá dtaobh/gi
s/ fríd an / tríd an /gi
s/ [ft]ríd na / trí na /gi
s/ go dtáinig / gur tháinig /gi
s/ go dtug / gur thug /gi
s/ go gcuala / gur chuala /gi
s/ in mo / i mo /gi
s/ le hinse / le hinsint /gi
s/ nach dtáinig / nár tháinig /gi
s/ nach dtug / nár thug /gi
s/\(^\| \)ní tháinig /\1níor tháinig /gi
s/\(^\| \)ní thug /\1níor thug /gi
s/ an phill / an+phill /gi
s/\(^\| \)gur phill /\1gur fhill /gi
s/\(^\| \)níor phill /\1níor fhill /gi
s/\(^\| \)sular phill /\1sular fhill /gi
s/\(^\| \)nár phill /\1nár fhill /gi
s/\(^\| \)ar phill /\1ar fhill /gi
s/\(^\| \)phill /\1d'fhill /gi
s/an+phill/an phill/gi
"
