print "1..2\n";

use Image::Info qw(image_info dim);

my $i = image_info("test.rle") || die;

#use Data::Dumper; print Dumper($i), "\n";

print "not " unless $i->{Compression} eq "RLE8" &&
                    $i->{BitsPerSample} == 8;
print "ok 1\n";

print "not " unless dim($i) eq "256x256";
print "ok 2\n";
