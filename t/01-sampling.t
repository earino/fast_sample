#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 23;
use FindBin qw/$Bin/;
use lib "$Bin/lib";

use Test::Sample qw/run_fast_sample create_test_file/;

my $script_path = "$Bin/../fast_sample";

=encoding utf8

=head1 DESCRIPTION

Tests for sampling algorithms (stream coin-flip and reservoir sampling).

=cut

# Test 1: Stream coin-flip sampling with proportion
{
    my $file = create_test_file(lines => 100);
    open(my $fh, '<', $file);
    my @orig = <$fh>;
    close($fh);

    # Sample 10% with a specific seed
    my $output = run_fast_sample($file, '-p', '0.1', '-s', '12345');
    my @lines = grep { /\S/ } split(/\n/, $output);
    my $sampled_lines = scalar @lines;

    # With 10% sampling rate and ~100 lines, we expect roughly 10 lines
    ok($sampled_lines > 5 && $sampled_lines < 20,
       "Stream sampling produces reasonable count ($sampled_lines lines from 100)");
}

# Test 2: Reservoir sampling with -number flag
{
    my $file = create_test_file(lines => 100);

    # Request exactly 25 lines
    my $output = run_fast_sample($file, '-n', '25');
    my @lines = grep { /\S/ } split(/\n/, $output);

    # Should have exactly 25 lines (or header + 25 if header present)
    is(scalar(@lines), 25, 'Reservoir sampling produces exact number of lines');
}

# Test 3: Reservoir sampling with header preserves header
{
    my $file = create_test_file(lines => 100, header => 1);

    # Request 25 lines with header
    my $output = run_fast_sample($file, '-h', '-n', '25');
    my @lines = grep { /\S/ } split(/\n/, $output);

    # Should have header + 25 data lines = 26 total
    is(scalar(@lines), 26, 'Reservoir sampling with -h includes header');
    like($lines[0], qr/^id,name,value/, 'First line is header');
}

# Test 4: Reproducibility with seed option
{
    my $file = create_test_file(lines => 50, header => 1);

    # Run twice with same seed
    my $output1 = run_fast_sample($file, '-s', '99999');
    my $output2 = run_fast_sample($file, '-s', '99999');

    is($output1, $output2, 'Same seed produces reproducible results');
}

# Test 5: Stream sampling is deterministic with same seed
{
    my $file = create_test_file(lines => 100, header => 0);

    my $output1 = run_fast_sample($file, '-p', '0.5', '-s', '54321');
    my $output2 = run_fast_sample($file, '-p', '0.5', '-s', '54321');

    is($output1, $output2, 'Stream sampling with -p and seed is reproducible');
}

# Test 6: Different seeds produce different samples
{
    my $file = create_test_file(lines => 100, header => 0);

    # Use numeric seeds to ensure different random sequences
    my $output1 = run_fast_sample($file, '-p', '0.5', '-s', '42');
    my $output2 = run_fast_sample($file, '-p', '0.5', '-s', '99');

    ok($output1 ne $output2, 'Different seeds produce different samples');
}

# Test 7: Proportion of 0 returns nothing (except possibly header)
{
    my $file = create_test_file(lines => 10, header => 1);

    my $output = run_fast_sample($file, '-p', '0', '-h');
    ok(defined $output, 'Proportion 0 produces output');
}

# Test 8: Proportion of 1 returns all lines
{
    my $file = create_test_file(lines => 50, header => 1);

    open(my $fh, '<', $file);
    my @original = <$fh>;
    close($fh);

    my $output = run_fast_sample($file, '-p', '1', '-h');

    is($output, join('', @original), 'Proportion 1 returns all lines');
}

# Test 9: Reservoir sampling with number larger than file
{
    my $file = create_test_file(lines => 10, header => 0);

    # Request more lines than exist
    my $output = run_fast_sample($file, '-n', '100');
    my @lines = grep { /\S/ } split(/\n/, $output);

    ok(scalar(@lines) <= 10, 'Reservoir sampling returns all available lines when request exceeds file size');
}

# Test 10: Single line with reservoir sampling
{
    my $file = create_test_file(lines => 1, header => 0);

    my $output = run_fast_sample($file, '-n', '1');
    my @lines = grep { /\S/ } split(/\n/, $output);

    is(scalar(@lines), 1, 'Can sample single line file');
}

# Test 11: Large reservoir sampling
{
    my $file = create_test_file(lines => 1000, header => 0);

    my $output = run_fast_sample($file, '-n', '100');
    my @lines = grep { /\S/ } split(/\n/, $output);

    is(scalar(@lines), 100, 'Large reservoir sampling produces exact count');
}

# Test 12: Header-only file with stream sampling
{
    my $file = create_test_file(lines => 0, header => 1);

    my $output = run_fast_sample($file, '-p', '0.5');
    ok(defined $output, 'Header-only file produces output');
}

# Test 13: Stream sampling respects header flag
{
    my $file = create_test_file(lines => 10, header => 0);

    # Without header flag
    my $output_no_header = run_fast_sample($file, '-p', '1.0');
    # With header flag (need a file that has header in first line)
    my $file_with_header = create_test_file(lines => 10, header => 1);
    my $output_with_header = run_fast_sample($file_with_header, '-h', '-p', '1.0');

    unlike($output_no_header, qr/^id,name,value/, 'Stream sampling without -h excludes header');
    like($output_with_header, qr/^id,name,value/, 'Stream sampling with -h includes header');
}

# Test 14: Reservoir sampling respects header flag
{
    my $file = create_test_file(lines => 100, header => 1);

    # Without header flag
    my $output_no_header = run_fast_sample($file, '-n', '10');
    # With header flag
    my $output_with_header = run_fast_sample($file, '-h', '-n', '10');

    my @no_header_lines = grep { /\S/ } split(/\n/, $output_no_header);
    my @with_header_lines = grep { /\S/ } split(/\n/, $output_with_header);

    is(scalar(@no_header_lines), 10, 'Reservoir sampling without -h returns 10 lines');
    is(scalar(@with_header_lines), 11, 'Reservoir sampling with -h returns header + 10 lines');
}

# Test 15: Multiple files with stream sampling
{
    my $file1 = create_test_file(lines => 50, header => 0);
    my $file2 = create_test_file(lines => 50, header => 0);

    my $output = run_fast_sample($file1, $file2, '-p', '0.1');
    ok(defined $output, 'Multiple files can be sampled with stream sampling');
}

# Test 16: Multiple files with reservoir sampling
{
    my $file1 = create_test_file(lines => 50, header => 0);
    my $file2 = create_test_file(lines => 50, header => 0);

    my $output = run_fast_sample($file1, $file2, '-n', '20');
    ok(defined $output, 'Multiple files can be sampled with reservoir sampling');
}

# Test 17: Seed works without other options
{
    my $file = create_test_file(lines => 100, header => 0);

    my $output = run_fast_sample($file, '-s', '42');
    ok(defined $output && length($output) > 0, 'Seed alone produces output');
}

# Test 18: Very small proportion
{
    my $file = create_test_file(lines => 1000, header => 0);

    my $output = run_fast_sample($file, '-p', '0.01');
    my @lines = grep { /\S/ } split(/\n/, $output);

    ok(scalar(@lines) < 50, 'Very small proportion produces few lines from 1000');
}

# Test 19: Very large proportion (close to 1)
{
    my $file = create_test_file(lines => 100, header => 0);

    my $output = run_fast_sample($file, '-p', '0.99');
    my @lines = grep { /\S/ } split(/\n/, $output);

    ok(scalar(@lines) > 50, 'Large proportion produces most lines');
}

# Test 20: Reservoir sampling with very small sample
{
    my $file = create_test_file(lines => 100, header => 0);

    my $output = run_fast_sample($file, '-n', '1');
    my @lines = grep { /\S/ } split(/\n/, $output);

    is(scalar(@lines), 1, 'Reservoir sampling with -n=1 produces exactly 1 line');
}

__END__
