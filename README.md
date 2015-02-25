# fast\_sample

fast\_sample - A script for rapidly sampling a proportion of lines from a file

# SYNOPSIS

fast\_sample \[options\] \[file ...\]

    Options:
     -proportion|p   The proportion of lines to sample (e.g. .5 for half.)
     -header|h       Always print the header for every file
     -seed|s         The random seed, for reproducibility
     -man|m          The full man page
     -help|?         This message

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

- **-help|h**

    Prints a brief help message and exits.

# DESCRIPTION

**fast\_sample** is a program that allows you to work with a subset of your
data. Sometimes you have a super large file, and you wish you could just
work with 5% of the data. **fast\_sample** let's you do this simply. It also
allows you to sample files reproducibly by simply specifying a random
number seed.

# AUTHOR

The home for **fast\_sample** is on github at https://github.com/earino/fast_sample

Eduardo Arino de la Rubia <earino@gmail.com>
