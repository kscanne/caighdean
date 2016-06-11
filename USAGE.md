
Pre-Processing
--------------
Only minimal pre-processing is required before running the standardizer
on a text.

* Input text should be encoded as UTF-8 Unicode.
* Words broken at the end of lines should be rejoined manually.
* If there are extended passages in English or any language other than Irish, they should be removed.
* Any SGML-like markup will be ignored.

Running
-------

Assume the text to be standardized is called `input.txt`, and has been saved in the same directory as the standardizer code and data files.  On Linux, or from a Terminal on Mac, run the following command:

	$ cat input.txt | bash tiomanai.sh > output.txt

This writes the standardization to the file output.txt in the following
format:

	Ní => Ní
	bhéadh => bheadh
	aoinne => aon duine
	i => in
	n-amhras => amhras
	nach => nach
	dairíribh => dáiríre
	a => a
	bhí => bhí
	sí => sí
	. => .
	\n => \n

There is a (rough) _detokenizer_ included in the repository if you
do not care about keeping the pre-standard forms and just want a clean
version of the standardized text.  Use this command, for example:

	$ cat output.txt | perl detokenize.pl -t > standard.txt

The detokenizer can also convert the usual output format into an alternate format that we used as part of the [New English-Irish Dictionary project](http://focloir.ie/):

	$ cat output.txt | perl detokenize.pl -f
	Ní ^bhéadh^ bheadh duine ar bith ^i^ in ^n-amhras^ amhras nach ^dairíribh^ dáiríre a bhí sí.
	Nuair a bhí sí réidh le ^h-imtheacht^ himeacht d'fhág sí slán agus beannacht ag ballaí na ^cisteanadh^ cistine.
	Bhí spéir bhog ^theith^ the ann agus ^néalltaí^ néaltaí bána mar ^bhéadh^ bheadh olann ann agus corr-réalt.
	...

Hacking
-------

The standardizer will never be perfect. In any non-trivial text there will be non-standard spellings or grammatical constructs the program has never seen before.  One option is to manually post-edit the output from the standardizer and be done with it.  A better option is to run the standardizer on a sample of your text, examine the output, and try to improve the standardizer before running it on the rest.  By so doing, you are likely to avoid making the same corrections over and over, and others users will benefit from your improvements as well.

This version of the standardizer was written specifically to make it easy for non-programmers to make improvements.  There are only three files you need to worry about:

* `pairs-local.txt`.  On each line of this file is a _standardization pair_ consisting of a pre-standard word, a space, and then the standardized form.  The primary collection of standardizations is contained in a separate file called `pairs.txt`; it uses the same format, but is generated automatically from my backend database and you should not edit it.  Any new pairs you want to add to the system should go in `pairs-local.txt`.
* `multi.txt`. This file contains standardization pairs where the pre-standard form consists of more than one word.  The file format is basically the same as `pairs-local.txt`, except that underscores must be used in place of any spaces in the pre-standard phrase.
* `spurious.txt`. Sometimes you will find that you are not happy with one of the built-in standardizations from `pairs.txt`. There could be an error, or simply a standardization that you do not like or agree with.  It is possible to "turn off" a given pair by placing it in the file `spurious.txt`.

After making changes to any of these files, you can rerun the program and you should see your improvements take effect.
