print "1..4\n";

use Image::Info qw(image_info dim html_dim);

my $info = image_info("img/test.gif");
my @dim = dim($info);

print "not" unless "@dim" eq "400 300";
print "ok 1\n";

print "not" unless dim($info) eq "400x300";
print "ok 2\n";

print "not " unless html_dim($info) eq "WIDTH=400 HEIGHT=300";
print "ok 3\n";

print "not " unless html_dim(image_info("README")) eq "";
print "ok 4\n";
