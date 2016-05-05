
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

The one resource _not_ contained in the repository is the Irish n-gram language model (roughly speaking, this is a table of probabilities of seeing a word in Irish if you know the previous two words). These statistics need to be stored a [Redis database](http://redis.io/) that the standardizer will access at runtime.

If you have a reasonably large corpus of (more or less) standard Irish, you can build your own n-gram model using the scripts in the `model` subdirectory. Just place your corpus in a plain text file, UTF-8 encoded, one sentence per line, in the `model` directory. Then edit the two variables at the top of `model/makefile`; the first should point to your clone of the `caighdean` repo, and the second should be the filename of your corpus (do *not* use the default name `corpus.txt`). Then:

	$ cd model
	$ make

You will need the [Redis Perl module](http://search.cpan.org/dist/Redis/), and the Redis server must be running on your machine for this to work.  This will take a while to run.  When it finishes, you will be ready to [start standardizing text](https://github.com/kscanne/caighdean/blob/master/USAGE.md).
