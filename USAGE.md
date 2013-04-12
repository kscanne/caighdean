
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

Hacking
-------

The standardizer will never be perfect. In any non-trivial text there will be non-standard spellings or grammatical constructs the program has never seen before.  One option is to postedit the output from the standardizer and be done with it.  A better option is to run the standardizer on a sample of your text, examine the output, and try to improve the standardizer.  By so doing, you are likely to avoid making the same corrections over and over, and others users will benefit from your improvements as well.

This version of the standardizer was written specifically to make it easy for non-programmers to make improvements.  There are only three files you need to worry about:

* `pairs-local.txt`.  This is a plain text file.  On each line is a _standardization pair_ consisting of a pre-standard word, a space, and then the standardized form.  The primary collection of standardizations is the file `pairs.txt`; it uses the same format, but is generated automatically from my backend database and you should not edit it.  Any new pairs you want to add to the system should go in `pairs-local.txt`.
* `multi.txt`. This file contains standardization pairs where the pre-standard form consists of more than one word.  The file format is basically the same as `pairs-local.txt`, except that underscores must be used in place of any spaces in the pre-standard phrase.
* `spurious.txt`. As mentioned above, there is a default collection of standardizations in `pairs.txt`. Sometimes, however, you will find that you are not happy with one of the default pairs.  There could be an error, or simply a standardization that you do not like or agree with.  It is possible to "turn off" a pair by placing it in the file `spurious.txt`.

After making changes to any of these files, you can rerun the program and you should see your improvements take effect.
