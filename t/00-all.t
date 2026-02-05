#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

=encoding utf8

=head1 DESCRIPTION

Master test runner for fast_sample test suite.

This file runs all the individual test files in order.
It can be used directly with prove:

    perl t/00-all.t

Or to run all tests in parallel:

    perl -MThread::Pool::Simple -e '...' t/00-all.t

=cut

# Load test utilities
use FindBin qw/$Bin/;
use lib "$Bin/lib";
use Test::Sample;

# Test files to run
my @test_files = (
    't/01-sampling.t',
    't/02-cli-flags.t',
    't/03-edge-cases.t',
);

# Skip DBF tests if dependencies not available
my $has_xbase = Test::Sample::has_xbase_module();
my $has_text_csv = Test::Sample::has_text_csv_module();

push @test_files, 't/04-dbflib.t' if $has_xbase && $has_text_csv;

# Don't declare a plan - let each test file manage its own
# This avoids "More than one plan found" errors
for my $file (@test_files) {
    ok(-e $file, "Test file exists: $file");

    # Run test file and capture output
    my $output = `perl -I$Bin/lib -I$Bin "$file" 2>&1`;

    # Check exit code and parse TAP for failures
    my $exit_code = $?;

    if ($exit_code == 0 && $output !~ /\b(\d+)\/(\d+)\s+failed/i) {
        pass("Tests in $file passed");
    } else {
        fail("Tests in $file failed");
    }
}

done_testing();

__END__
