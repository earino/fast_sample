#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 18;
use FindBin qw/$Bin/;
use lib "$Bin/lib";

use Test::Sample qw/run_fast_sample create_test_file/;

my $script_path = "$Bin/../fast_sample";

=encoding utf8

=head1 DESCRIPTION

Basic smoke tests for fast_sample.

=cut

ok(-e $script_path, 'Script file exists');

# Test 1: Script runs without error on existing file
{
    my $file = create_test_file(lines => 10);
    my $output = run_fast_sample($file);
    ok(defined $output && length($output) > 0, 'Script runs and produces output');
}

# Test 2: --man option shows help
{
    my $output = `perl "$script_path" --man 2>&1`;
    is($?, 0, 'Script exits with code 0 for --man');
    like($output, qr/^\s*fast_sample/, 'Man page contains script name');
    like($output, qr/SYNOPSIS/, 'Man page contains SYNOPSIS section');
}

# Test 3: Basic sampling produces fewer lines than original
{
    my $file = create_test_file(lines => 100);
    open(my $fh, '<', $file);
    my @lines = <$fh>;
    close($fh);
    my $original_lines = scalar @lines;

    my $output = run_fast_sample($file, '-p', '0.1');
    my @sampled_lines = grep { /\S/ } split(/\n/, $output);

    ok(scalar(@sampled_lines) < $original_lines, 'Sampling produces fewer lines than original');
}

# Test 4: Error handling for invalid file
{
    my $output = `perl "$script_path" test_nonexistent_file.csv 2>&1`;
    like($output, qr/doesn't exist/, 'Error message for non-existent file');
}

# Test 5: Error handling for unreadable file
{
    my $file = create_test_file(lines => 5);
    chmod(0, $file);
    my $output = `perl "$script_path" "$file" 2>&1`;
    like($output, qr/can not be read/i, 'Error message for unreadable file');
    chmod(0644, $file);
}

# Test 6: Help with short -h option (header flag) doesn't error
{
    my $file = create_test_file(lines => 5);
    my $output = run_fast_sample($file, '-h');
    ok(defined $output, 'Header flag -h does not cause error');
}

# Test 7: Verify output contains header when -h flag used
{
    my $file = create_test_file(lines => 10, header => 1);
    my $output = run_fast_sample($file, '-h', '-p', '1.0');
    like($output, qr/^id,name,value/, 'Output contains header line');
}

# Test 8: Verify output without header when -h not used
{
    my $file = create_test_file(lines => 10, header => 0);
    my $output = run_fast_sample($file, '-p', '1.0');
    unlike($output, qr/^id,name,value/, 'Output without -h does not start with header');
}

# Test 9: Empty file handling
{
    my $file = create_test_file(lines => 0, header => 1);
    my $output = run_fast_sample($file, '-p', '0');
    ok(defined $output, 'Empty sampling produces defined output');
}

# Test 10: Invalid proportion (greater than 1)
{
    my $file = create_test_file(lines => 5);
    my $output = `perl "$script_path" -p 1.5 "$file" 2>&1`;
    like($output, qr/Proportion must be between 0 and 1/, 'Error for proportion > 1');
}

# Test 11: Invalid proportion (negative)
{
    my $file = create_test_file(lines => 5);
    my $output = `perl "$script_path" -p -0.1 "$file" 2>&1`;
    like($output, qr/Proportion must be between 0 and 1/, 'Error for negative proportion');
}

# Test 12: Invalid option handling
{
    my $file = create_test_file(lines => 5);
    my $output = `perl "$script_path" --invalid-option "$file" 2>&1`;
    like($output, qr/Unknown option|usage/i, 'Error message for invalid options');
}

# Test 13: Multiple files
{
    my $file1 = create_test_file(lines => 5, header => 0);
    my $file2 = create_test_file(lines => 5, header => 0);
    my $output = run_fast_sample($file1, $file2);
    ok(defined $output, 'Multiple files can be processed');
}

# Test 14: Seed makes sampling reproducible
{
    my $file = create_test_file(lines => 50, header => 0);
    my $output1 = run_fast_sample($file, '-s', '42');
    my $output2 = run_fast_sample($file, '-s', '42');
    is($output1, $output2, 'Same seed produces identical output');
}

# Test 15: Different seeds produce different results
{
    my $file = create_test_file(lines => 100, header => 0);

    # Use -p with a moderate value so we get some lines but not all
    my $output1 = run_fast_sample($file, '-p', '0.5', '-s', '42');
    my $output2 = run_fast_sample($file, '-p', '0.5', '-s', '999');

    # With moderate proportion and different seeds, results should differ
    is($output1 ne $output2 ? 1 : 0, 1, 'Different seeds produce different samples');
}

__END__
