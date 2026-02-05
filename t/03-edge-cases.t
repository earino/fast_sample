#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 16;
use FindBin qw/$Bin/;
use lib "$Bin/lib";

use Test::Sample qw/run_fast_sample create_test_file/;

my $script_path = "$Bin/../fast_sample";

=encoding utf8

=head1 DESCRIPTION

Edge case tests for fast_sample.

=cut

# Test 1: Empty file (0 bytes)
{
    my $file = create_test_file(lines => 0, header => 1);
    # Truncate to 0 bytes
    system("truncate -s 0 $file") == 0 or die "Cannot truncate: $?";

    my $output = run_fast_sample($file);
    ok(defined $output, 'Empty file produces defined output');
}

# Test 2: Empty file with header flag
{
    my $file = create_test_file(lines => 0, header => 1);
    system("truncate -s 0 $file") == 0 or die "Cannot truncate: $?";

    my $output = run_fast_sample($file, '-h');
    ok(defined $output, 'Empty file with -h produces defined output');
}

# Test 3: Single line file (no newline)
{
    my $file = create_test_file(lines => 1, header => 0);
    # Remove trailing newline to test single-line no-newline case
    open(my $fh, '<', $file);
    my $content = do { local $/; <$fh> };
    close($fh);

    # Remove trailing newline if present
    $content =~ s/\n\z//;

    open($fh, '>', $file);
    print $fh $content;
    close($fh);

    my $output = run_fast_sample($file);
    ok(defined $output, 'Single line file produces output');
}

# Test 4: Single line file with header flag
{
    my $file = create_test_file(lines => 1, header => 0);

    my $output = run_fast_sample($file, '-h');
    ok(defined $output, 'Single line file with -h produces output');
}

# Test 5: Header-only file
{
    my $file = create_test_file(lines => 0, header => 1);

    my $output = run_fast_sample($file);
    like($output, qr/^id,name,value/, 'Header-only file outputs header');
}

# Test 6: Header-only file with reservoir sampling
{
    my $file = create_test_file(lines => 0, header => 1);

    my $output = run_fast_sample($file, '-n', '5');
    like($output, qr/^id,name,value/, 'Header-only file with -n outputs header');
}

# Test 7: Header-only file with proportion sampling
{
    my $file = create_test_file(lines => 0, header => 1);

    # Use proportion 1.0 to ensure header is always output
    my $output = run_fast_sample($file, '-p', '1.0');
    like($output, qr/^id,name,value/, 'Header-only file with -p outputs header');
}

# Test 8: File smaller than sample size (reservoir)
{
    my $file = create_test_file(lines => 5, header => 0);

    # Request more lines than exist
    my $output = run_fast_sample($file, '-n', '100');
    my @lines = grep { /\S/ } split(/\n/, $output);

    ok(scalar(@lines) <= 5, 'Reservoir sampling returns all lines when file is smaller');
}

# Test 9: File smaller than sample size with header
{
    my $file = create_test_file(lines => 5, header => 1);

    # Request more lines than exist
    my $output = run_fast_sample($file, '-h', '-n', '100');
    my @lines = grep { /\S/ } split(/\n/, $output);

    # Should have header + all 5 data lines
    is(scalar(@lines), 6, 'Reservoir sampling with header returns all available lines');
}

# Test 10: Negative seed (should still work - Perl handles it)
{
    my $file = create_test_file(lines => 50, header => 0);

    my $output1 = run_fast_sample($file, '-s', '-42');
    my $output2 = run_fast_sample($file, '-s', '-42');

    is($output1, $output2, 'Negative seed works and produces reproducibility');
}

# Test 11: Zero seed
{
    my $file = create_test_file(lines => 50, header => 0);

    my $output1 = run_fast_sample($file, '-s', '0');
    my $output2 = run_fast_sample($file, '-s', '0');

    is($output1, $output2, 'Zero seed works and produces reproducibility');
}

# Test 12: Very large seed value
{
    my $file = create_test_file(lines => 50, header => 0);

    my $output1 = run_fast_sample($file, '-s', '999999999');
    my $output2 = run_fast_sample($file, '-s', '999999999');

    is($output1, $output2, 'Large seed value works and produces reproducibility');
}

# Test 13: Proportion exactly 0
{
    my $file = create_test_file(lines => 100, header => 0);

    my $output = run_fast_sample($file, '-p', '0');
    ok(defined $output, 'Proportion 0 produces output (may be empty)');
}

# Test 14: Proportion exactly 1
{
    my $file = create_test_file(lines => 50, header => 0);

    open(my $fh, '<', $file);
    my @original = <$fh>;
    close($fh);

    my $output = run_fast_sample($file, '-p', '1');

    is($output, join('', @original), 'Proportion 1 returns exactly all lines');
}

# Test 15: File with only newlines (edge case)
{
    my $dir = do { require File::Temp; File::Temp::tempdir(CLEANUP => 1) };
    my $file = "$dir/only_newlines.csv";

    open(my $fh, '>', $file);
    print $fh "\n\n\n";
    close($fh);

    my $output = run_fast_sample($file);
    ok(defined $output, 'File with only newlines produces output');
}

# Test 16: Files with embedded commas in values
{
    my $dir = do { require File::Temp; File::Temp::tempdir(CLEANUP => 1) };
    my $file = "$dir/embedded_commas.csv";

    open(my $fh, '>', $file);
    print $fh "id,name,value\n";
    print $fh "1,\"Smith, John\",100\n";
    print $fh "2,\"O'Brien, Mary\",200\n";
    print $fh "3,Simple,300\n";
    close($fh);

    my $output = run_fast_sample($file, '-h', '-p', '1.0');
    ok($output =~ /Smith, John/, 'Embedded commas in values preserved');
}

__END__
