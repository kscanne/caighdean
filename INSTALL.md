
The standardizer is written in Perl.  Because of this, it is
easiest to install and run it on a computer where Perl is available
by default (i.e. Mac OS X or Linux). To run it on Windows, you will
need to install something like [ActiveState Perl](http://www.activestate.com/activeperl).

Almost everything you need to run the standardizer is contained
in this github repository.  I recommend strongly that you access the code
and data files by installing a git client and cloning the repository
to your computer.  By doing so, you will be able to 
keep up with the latest development, bug fixes, and contributions
from other users.

If you would rather not mess with git, then you can simply
[download a ZIP](https://github.com/kscanne/caighdean/archive/master.zip)
containing all of the files in the repository.

The one file _not_ contained in the repository is the raw statistical language model `ngrams.txt` (roughly speaking, this contains a table of probabilities of seeing an word in Irish if you know the previous two words).  It currently weighs in at about 500MB uncompressed, and is therefore much too big to maintain on github. It should be placed in the same directory as all of the other files in the repository.  Contact me directly if you need a copy of `ngrams.txt`.

The default behavior of the standardizer is to read the statistical 
language models from a database.  You will need to have `libdb` and the
Perl modules `DB_File` and `DBM_Filter` installed for this to work.
Once you have the repository files and `ngrams.txt`, run this command to 
build the databases:

	$ perl builddb.pl

This will take a while to run.  When it finishes, you will have two new files named `prob.db` and `smooth.db`, and you are ready to [start standardizing text](https://github.com/kscanne/caighdean/blob/master/USAGE.md).

If you do not have `libdb` installed, you can try having the standardizer
read the language model `ngrams.txt` directly into RAM.   For this,
just set the value of the `$db` flag in `caighdean.pl` to 0:

	my $db = 0;
 
If you go this route, you will need to run the standardizer
on a reasonably powerful computer with plenty of RAM.  On my Linux server
with 12GB RAM and a pretty fast drive it takes about a minute and
half to load the language models.  On a MacBook Pro with 8GB RAM it
takes about 12 minutes.  Once the models are loaded, the actual
standardization process is pretty fast; better than 200K words per minute on the Linux server.
