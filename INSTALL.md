
The standardizer is written in Perl.  Because of this, it is be
easiest to install and run it on a computer where Perl is available
by default (i.e. Mac OS X or Linux). To run it on Windows, you will
need to install something like [ActiveState Perl](http://www.activestate.com/activeperl).

You should also consider installing and running the standardizer
on a reasonably powerful computer.  It tries to load some very large
statistical language models into memory, and this can be slow if you
have limited RAM and it starts swapping to disk.  On my Linux server
with 12GB RAM and a pretty fast drive it takes about a minute and
half to load the language models.  On a MacBook Pro with 8GB RAM it
takes about 12 minutes.  Once the models are loaded the actual
standardization process is 
pretty fast; better than 200K words per minute on the Linux server.

Almost everything you need to run the standardizer is contained
in this github repository.  I recommend strongly that you access the code
and data files by installing a git client and cloning the repository
to your computer.  By doing so, you will be able to 
keep up with the latest development, bug fixes, and contributions
from other users.

If you would rather not mess with git, then you can simply
[download a ZIP file](https://github.com/kscanne/caighdean/archive/master.zip)
containing all of the files in the repository.

The one file _not_ contained in the repository is the statistical language model `ngrams.txt` (roughly speaking, this contains a table of probabilities of seeing an word in Irish if you know the previous two words).  It currently weighs in at about 500MB uncompressed, and is therefore much too big to maintain on github. It should be placed in the same directory as all of the other files in the repository.  Contact me directly if you need a copy of `ngrams.txt`.
