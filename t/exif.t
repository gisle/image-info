print "1..2\n";

use Image::Info qw(image_info dim);

my $i = image_info("test.jpg") || die;

#use Data::Dump; print Data::Dump::dump($i), "\n";

print "not " unless $i->{DateTimeDigitized} eq "1999:12:06 16:38:40" &&
                    $i->{Make} eq "OLYMPUS OPTICAL CO.,LTD";
print "ok 1\n";

print "not " unless dim($i) eq "640×480";
print "ok 2\n";
