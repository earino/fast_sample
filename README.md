# fast\_sample

fast\_sample - A script for rapidly sampling a proportion of lines from a file

# SYNOPSIS

fast\_sample \[options\] \[file ...\]

    Options:
     -proportion|p   The proportion of lines to sample (e.g. .5 for half.)
     -header|h       Always print the header for every file
     -seed|s         The random seed, for reproducibility
     -man|m          The full man page

# OPTIONS

- **-proportion|p**

    This is a floating point number between 0 and 1 which determines the proportion
    of lines to sample from the input files.

- **-header|h**

    This is a boolean flag, if it exists then the first line of every file will be
    printed. This is useful for when you want to keep the header of a CSV file.

- **-seed|s**

    This is an integer flag, it is the seed passed to the random number generator
    which determines which lines are sampled. If you want to make your research
    reproducible, make sure to specify a seed, and the same lines will always
    be selected.

- **-man|m**

    The man page for fast\_sample.

# DESCRIPTION

**fast\_sample** is a program that allows you to work with a subset of your
data. Sometimes you have a super large file, and you wish you could just
work with 5% of the data. **fast\_sample** let's you do this simply. It also
allows you to sample files reproducibly by simply specifying a random
number seed. **fast\_sample** currently supports line-by-line textual 
formats such as CSV, and the DBF format.

# DEPENDENCIES

**fast\_sample** attempts to be as smart as possible about requiring 3rd
party modules. If you are just going to use it for just sampling out of
text files (line by line format such as CSV) it should work without the
addition of any 3rd party modules, and any perl (I think going back as
far as 5.6) will work.

However, if you want to sample binary formats (currently only dbf is
supported), you will unfortunately need to install two modules. In order
to sample DBFs you need [XBase](https://metacpan.org/pod/XBase) for parsing dbf files, and [Text::CSV](https://metacpan.org/pod/Text::CSV)
in order to have "correct" CSV file generation. I could have hand-coded
a chintzy CSV generator, but it would be wrong and would handle weird
stuff incorrectly (like embedded newlines.)

# INSTALLATION

## Mac and Linux

**fast\_sample** is very lightweight and requires no 3rd party packages
installed other than a default Perl installation. Perl comes installed
on OSX and Linux, so for both of those, simply clone the repository
and you should be able to execute it at the command line. If you 
want to have it available just for your user, copy the **fast\_sample**
script to your ~/bin as follows: 

    cp fast_sample ~/bin

if you want it available for all users in the system, copy it to your
system /usr/local/bin using the following command:

    sudo cp fast_sample /usr/local/bin

Make sure that the directory you copy the script to is in your search
path. So to summarize, a full installation would look as follows:

    # first we clone the repo
    % git clone https://github.com/earino/fast_sample.git
    Cloning into 'fast_sample'...
    remote: Counting objects: 31, done.
    remote: Compressing objects: 100% (26/26), done.
    remote: Total 31 (delta 14), reused 18 (delta 5), pack-reused 0
    Unpacking objects: 100% (31/31), done.
    Checking connectivity... done.

    # then we go into the newly cloned directory
    % cd fast_sample

    # then we copy the script to our /usr/local/bin
    % sudo cp fast_sample /usr/local/bin
    Password:
    %

## Windows

I have not installed a perl script on windows in a very long time, so
I unfortunately do not know how to do this. If you want to use 
**fast\_sample** on Windows, drop me a note and I'll figure out how to
get this done :-)

# PERFORMANCE

**fast\_sample** attempts to be as fast as possible. Sampling should be
effortless even when dealing with huge files.

    $ ls -alh big.csv
    -rw-r--r--  1 earino  staff   3.1G Feb  7 09:15 big.csv
    $ time fast_sample -h -p .001 big.csv > sampled.csv

    real    0m5.949s
    user    0m5.209s
    sys     0m0.694s
    $ wc -l big.csv
     12174947 big.csv
    $ wc -l sampled.csv
        12277 sampled.csv

# AUTHOR

The home for **fast\_sample** is on github at https://github.com/earino/fast\_sample

Eduardo Arino de la Rubia <earino@gmail.com>
