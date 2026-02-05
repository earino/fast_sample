#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 19;
use FindBin qw/$Bin/;
use lib "$Bin/lib";

use Test::Sample qw/run_fast_sample create_test_file/;

my $script_path = "$Bin/../fast_sample";

=encoding utf8

=head1 DESCRIPTION

Tests for CLI argument parsing and validation.

=cut

# Test 1: Help with --help flag
{
    my $output = `perl "$script_path" --help 2>&1`;
    like($output, qr/usage|Options/i, 'Help flag displays usage');
}

# Test 2: Help with -h (header) does not error
{
    my $file = create_test_file(lines => 5);
    my $output = run_fast_sample($file, '-h');
    ok(defined $output, 'Header flag -h works without error');
}

# Test 3: Proportion option with valid value (0.5)
{
    my $file = create_test_file(lines => 100);
    my $output = run_fast_sample($file, '-p', '0.5');
    ok(defined $output && length($output) > 0, '-p 0.5 works correctly');
}

# Test 4: Proportion option with decimal (0.25)
{
    my $file = create_test_file(lines => 100);
    my $output = run_fast_sample($file, '-p', '0.25');
    ok(defined $output && length($output) > 0, '-p 0.25 works correctly');
}

# Test 5: Proportion option with invalid value (> 1)
{
    my $file = create_test_file(lines => 5);
    my $output = `perl "$script_path" -p 1.5 "$file" 2>&1`;
    like($output, qr/Proportion must be between 0 and 1/, '-p > 1 is rejected');
}

# Test 6: Proportion option with invalid value (< 0)
{
    my $file = create_test_file(lines => 5);
    my $output = `perl "$script_path" -p -0.1 "$file" 2>&1`;
    like($output, qr/Proportion must be between 0 and 1/, '-p < 0 is rejected');
}

# Test 7: Number option with valid value
{
    my $file = create_test_file(lines => 100);
    my $output = run_fast_sample($file, '-n', '10');
    my @lines = grep { /\S/ } split(/\n/, $output);
    is(scalar(@lines), 10, '-n 10 works correctly');
}

# Test 8: Number option with zero
{
    my $file = create_test_file(lines => 10);
    my $output = run_fast_sample($file, '-n', '0');
    ok(defined $output, '-n 0 does not crash');
}

# Test 9: Seed option with integer value
{
    my $file = create_test_file(lines => 50);
    my $output1 = run_fast_sample($file, '-s', '12345');
    my $output2 = run_fast_sample($file, '-s', '12345');
    is($output1, $output2, '-s option sets seed correctly');
}

# Test 10: Seed option with string value (converts to number)
{
    my $file = create_test_file(lines => 50);
    my $output1 = run_fast_sample($file, '-s', 'abc123');
    my $output2 = run_fast_sample($file, '-s', 'abc123');
    is($output1, $output2, '-s option accepts string seed (converted to number)');
}

# Test 11: Conflicting options (-n and -p) are rejected
{
    my $file = create_test_file(lines => 100);
    my $output = `perl "$script_path" -n 10 -p 0.5 "$file" 2>&1`;
    like($output, qr/Cannot specify both -number and -proportion/i,
         'Conflicting options -n and -p are rejected');
}

# Test 12: Missing file error
{
    my $output = `perl "$script_path" -p 0.5 nonexistent.csv 2>&1`;
    like($output, qr/doesn't exist|Cannot open/, 'Missing file produces error');
}

# Test 13: Unknown option error
{
    my $file = create_test_file(lines => 5);
    my $output = `perl "$script_path" --unknown-option "$file" 2>&1`;
    like($output, qr/Unknown option|usage/i, 'Unknown option produces error');
}

# Test 14: Header-only with proportion
{
    my $file = create_test_file(lines => 0, header => 1);
    my $output = run_fast_sample($file, '-h', '-p', '0.5');
    ok(defined $output, 'Header-only file with -h and -p works');
}

# Test 15: Multiple files with header flag
{
    my $file1 = create_test_file(lines => 10, header => 1);
    my $file2 = create_test_file(lines => 10, header => 1);

    my $output = run_fast_sample($file1, $file2, '-h', '-p', '1.0');

    ok($output =~ /^id,name,value/m, 'Header appears for multiple files');
}

# Test 16: Only --man flag
{
    my $output = `perl "$script_path" --man 2>&1`;
    is($?, 0, '--man exits with code 0');
    like($output, qr/fast_sample/, 'Man page contains script name');
}

# Test 17: Combination of --man and other flags (man takes precedence)
{
    my $file = create_test_file(lines => 5);
    my $output = `perl "$script_path" --man -p 0.5 "$file" 2>&1`;
    is($?, 0, 'Man flag takes precedence over other flags');
}

# Test 18: Long option names work
{
    my $file = create_test_file(lines => 50, header => 0);
    # Use the same seed to ensure reproducibility
    my $output1 = run_fast_sample($file, '--proportion', '0.5', '-s', '12345');
    my $output2 = run_fast_sample($file, '--proportion', '0.5', '-s', '12345');

    is($output1, $output2, '--proportion long option works');
}

__END__
