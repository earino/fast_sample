package Test::Sample;

use 5.014;
use strict;
use warnings;
use Exporter 'import';
use File::Temp qw/tempdir tempfile/;
use File::Spec;

our @EXPORT_OK = qw/
    run_fast_sample
    create_test_file
    create_test_dbf
    has_xbase_module
    has_text_csv_module
/;

# Derive script path relative to t/lib/Test/Sample.pm -> ../../.. -> repo root
our $FAST_SAMPLE_PATH = do {
    my ($vol, $dir, $file) = File::Spec->splitpath(File::Spec->rel2abs(__FILE__));
    File::Spec->catfile($dir, '..', '..', '..', 'fast_sample');
};

=encoding utf8

=head1 NAME

Test::Sample - Test utilities for fast_sample

=cut

our $VERSION = '0.01';

=over 4

=item run_fast_sample($file, @args)

Runs the fast_sample script with the given file and arguments.
Returns the merged stdout/stderr output.

=cut

sub run_fast_sample {
    my ($file, @args) = @_;
    my $perl_path = $^X;
    my $cmd = qq{$perl_path "$FAST_SAMPLE_PATH" @args "$file"};
    my $output = `$cmd 2>&1`;
    return $output;
}

=item create_test_file(%options)

Creates a temporary test file with the specified options.
Returns the path to the temp file.

Options:
- lines => N     Number of data lines (default: 10)
- header => BOOL Add a header line (default: 0)

=cut

sub create_test_file {
    my %opts = @_;

    my $dir = tempdir(CLEANUP => 1);
    my ($fh, $filename) = tempfile(SUFFIX => '.csv', DIR => $dir);

    my $content = '';
    $content .= "id,name,value\n" if $opts{header};

    my $num_lines = $opts{lines} // 10;
    for my $i (1 .. $num_lines) {
        $content .= "$i,item$i," . int(rand(1000)) . "\n";
    }

    print $fh $content;
    close($fh);

    return $filename;
}

=item create_test_dbf(%options)

Creates a temporary DBF test file if XBase module is available.
Returns the path to the temp file, or undef if XBase not available.

Options:
- records => N   Number of records (default: 10)

=cut

sub create_test_dbf {
    my %opts = @_;

    return undef unless has_xbase_module();

    my $dir = tempdir(CLEANUP => 1);
    my $filename = "$dir/test.dbf";

    require XBase;

    my @field_defs = (
        ['ID', 'N', 10, 0],
        ['NAME', 'C', 50, 0],
        ['VALUE', 'N', 10, 0],
    );

    my $dbf = new XBase $filename, -create => 1, -field_defs => \@field_defs
        or die "Cannot create DBF: " . XBase->errstr;

    my $num_records = $opts{records} // 10;
    for my $i (1 .. $num_records) {
        $dbf->add_record([$i, "Record$i", int(rand(1000))]);
    }

    $dbf->close;

    return $filename;
}

=item has_xbase_module()

Returns true if XBase module is available.

=cut

sub has_xbase_module {
    return eval { require XBase; 1 };
}

=item has_text_csv_module()

Returns true if Text::CSV module is available.

=cut

sub has_text_csv_module {
    return eval { require Text::CSV; 1 };
}

1;

__END__
