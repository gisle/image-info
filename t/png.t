print "1..2\n";

use Image::Info qw(image_info dim);

my $i = image_info("test.png") || die;

use Data::Dump; print Data::Dump::dump($i), "\n";

print "not " unless $i->{ColorType} eq "RGB" &&
                    $i->{LastModificationTime} eq "1999-12-17 16:09:37";
print "ok 1\n";

print "not " unless dim($i) eq "400×300";
print "ok 2\n";
