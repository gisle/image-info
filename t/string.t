#!perl -w

if ($] < 5.008) {
    eval {
	require IO::String;
    };
    if ($@) {
	print "1..0\n";
	print $@;
	exit;
    }
}

my @tests = glob("test.*");

print "1..", scalar(@tests), "\n";

use Image::Info qw(image_info);

my $testno = 1;
for my $file (@tests) {
    print "# $file\n";

    my $h1 = image_info($file);

    my $img = cat($file);
    my $h2 = image_info(\$img);

    print "not " unless hash_equal($h1, $h2);
    print "ok $testno\n";
    $testno++;
}

sub cat {
    my $file = shift;
    local(*F, $/);
    open(F, $file) || die "Can't open $file: $!";
    binmode F;
    my $c = <F>;
    close(F);
    $c;
}

sub hash_equal {
    my($h1, $h2) = @_;
    # This is a sloppy compare, but good enough for this
    # test script
    my @k1 = sort keys %$h1;
    my @k2 = sort keys %$h2;
    return 0 if "@k1" ne "@k2";
    for (@k1) {
	next if ref($h1->{$_});
	return 0 if ref($h2->{$_});
	#print "comparing $_: $h1->{$_} == $h2->{$_}?\n";
	return 0 if $h1->{$_} ne $h2->{$_};
    }
    return 1;
}
