#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use FindBin qw/$Bin/;
use lib "$Bin/lib";

use Test::Sample qw/run_fast_sample create_test_dbf has_xbase_module has_text_csv_module/;

my $script_path = "$Bin/../fast_sample";

=encoding utf8

=head1 DESCRIPTION

DBF file tests - only runs if XBase and Text::CSV modules are installed.

=cut

plan skip_all => 'XBase module not installed'
    unless has_xbase_module();
plan skip_all => 'Text::CSV module not installed'
    unless has_text_csv_module();

my $has_dbf_support = has_xbase_module() && has_text_csv_module();
plan skip_all => 'DBF support not available'
    unless $has_dbf_support;

# Test 1: Basic DBF sampling with proportion
{
    my $dbf = create_test_dbf(records => 50);
    ok(defined $dbf, 'DBF file created successfully');

    my $output = run_fast_sample($dbf, '-p', '0.5');
    ok(defined $output && length($output) > 0, 'DBF file can be sampled with -p');
}

# Test 2: DBF reservoir sampling with number
{
    my $dbf = create_test_dbf(records => 50);
    ok(defined $dbf, 'DBF file created successfully');

    my $output = run_fast_sample($dbf, '-n', '10');
    my @lines = grep { /\S/ } split(/\n/, $output);
    is(scalar(@lines), 10, 'DBF reservoir sampling produces exact count');
}

# Test 3: DBF sampling with header flag
{
    my $dbf = create_test_dbf(records => 50);
    ok(defined $dbf, 'DBF file created successfully');

    my $output = run_fast_sample($dbf, '-h', '-p', '1.0');
    ok($output =~ /ID,NAME,VALUE/i, 'DBF sampling with -h includes headers');
}

# Test 4: DBF reproducibility with seed
{
    my $dbf = create_test_dbf(records => 50);
    ok(defined $dbf, 'DBF file created successfully');

    my $output1 = run_fast_sample($dbf, '-s', '42');
    my $output2 = run_fast_sample($dbf, '-s', '42');

    is($output1, $output2, 'DBF sampling with seed is reproducible');
}

# Test 5: DBF sampling respects deleted records
{
    my $dir = do { require File::Temp; File::Temp::tempdir(CLEANUP => 1) };
    my $dbf = "$dir/deleted.dbf";

    require XBase;

    my @field_defs = (
        ['ID', 'N', 10, 0],
        ['NAME', 'C', 50, 0],
    );

    my $table = new XBase $dbf, -create => 1, -field_defs => \@field_defs
        or die "Cannot create DBF: " . XBase->errstr;

    # Add 10 records
    for my $i (1 .. 10) {
        $table->add_record([$i, "Record$i"]);
    }

    # Mark record 2 as deleted (first byte is deletion flag)
    my $fh;
    open($fh, '+<', $dbf) or die "Cannot reopen: $!";
    # Move to record 2 position - after first record (13 bytes for our fields)
    seek($fh, 13, 0);
    print $fh "\x01";
    close($fh);

    my $output = run_fast_sample($dbf, '-p', '1.0');
    ok($output !~ /Record2/, 'Deleted records are excluded from output');
}

# Test 6: Empty DBF file
{
    my $dir = do { require File::Temp; File::Temp::tempdir(CLEANUP => 1) };
    my $dbf = "$dir/empty.dbf";

    require XBase;

    my @field_defs = (
        ['ID', 'N', 10, 0],
    );

    my $table = new XBase $dbf, -create => 1, -field_defs => \@field_defs
        or die "Cannot create empty DBF: " . XBase->errstr;
    $table->close;

    my $output = run_fast_sample($dbf, '-p', '1.0');
    ok(defined $output, 'Empty DBF produces output');
}

# Test 7: Single record DBF
{
    my $dbf = create_test_dbf(records => 1);
    ok(defined $dbf, 'Single record DBF created');

    my $output = run_fast_sample($dbf, '-n', '1');
    ok(defined $output && length($output) > 0, 'Single record DBF can be sampled');
}

# Test 8: Large DBF file sampling
{
    my $dbf = create_test_dbf(records => 100);
    ok(defined $dbf, 'Large DBF created');

    my $output = run_fast_sample($dbf, '-n', '50');
    my @lines = grep { /\S/ } split(/\n/, $output);

    is(scalar(@lines), 50, 'Large DBF reservoir sampling works');
}

# Test 9: Multiple DBF files
{
    my $dbf1 = create_test_dbf(records => 10);
    ok(defined $dbf1, 'First DBF created');
    my $dbf2 = create_test_dbf(records => 10);
    ok(defined $dbf2, 'Second DBF created');

    my $output = run_fast_sample($dbf1, $dbf2);
    ok(defined $output && length($output) > 0, 'Multiple DBF files can be sampled');
}

# Test 10: DBF with header and proportion
{
    my $dbf = create_test_dbf(records => 100);
    ok(defined $dbf, 'DBF with records created');

    my $output = run_fast_sample($dbf, '-h', '-p', '0.1');
    my @lines = grep { /\S/ } split(/\n/, $output);

    ok($output =~ /^ID,NAME,VALUE/i, 'DBF with -h and -p has header');
    ok(scalar(@lines) <= 11, 'DBF with -h and small proportion has reasonable output');
}

__END__
