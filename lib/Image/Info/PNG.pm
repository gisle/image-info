package Image::Info::PNG;

# Copyright 1999, Gisle Aas.
#
# This library is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

use strict;
use base 'Image::Info';

sub my_read
{
    my($source, $len) = @_;
    my $buf;
    my $n = read($source, $buf, $len);
    die "read failed: $!" unless defined $n;
    die "short read ($len/$n)" unless $n == $len;
    $buf;
}


sub process_file
{
    my($info, $fh) = @_;

    my $signature = my_read($fh, 8);
    die "Bad PNG signature"
	unless $signature eq "\x89PNG\x0d\x0a\x1a\x0a";

    while (1) {
        my($len, $type) = unpack("Na4", my_read($fh, 8));
        $info->push_info(0, "PNG_Chunks", $type) unless $type eq "IDAT";
        last if $type eq "IEND";
        my $data = my_read($fh, $len + 4);
	my $crc = unpack("N", substr($data, -4, 4, ""));
	if ($type eq "IHDR" && $len == 13) {
	    my($w, $h, $depth, $ctype, $compression, $filter, $interlace) =
		unpack("NNCCCCC", $data);
	    $ctype = {
		      0 => "GrayScale",
		      2 => "TrueColor",
		      3 => "IndexedColor",
		      4 => "GrayScale/Alpha",
		      6 => "TrueColor/Alph",
		     }->{$ctype} || $ctype;

	    $compression = "Deflate" if $compression == 0;
	    $filter = "Adaptive" if $filter == 0;
	    $interlace = "Adam7" if $interlace == 1;

	    $info->push_info(0, "ImageWidth", $w);
	    $info->push_info(0, "ImageLength", $h);
	    $info->push_info(0, "BitDepth", $depth);
	    $info->push_info(0, "ColorType", $ctype);
	    $info->push_info(0, "Compression", $compression);
	    $info->push_info(0, "Filter", $filter);
	    $info->push_info(0, "Interlace", $interlace);
	}
	elsif ($type eq "gAMA" && $len == 4) {
	    $info->push_info(0, "Gamma", unpack("N", $data)/100_000);
	}
	elsif ($type eq "tEXt") {
	    my($key, $val) = split(/\0/, $data, 2);
	    # XXX should make sure $key is not in conflict with any
	    # other key we might generate
	    $info->push_info(0, $key, $val);
	}
	elsif ($type eq "tIME" && $len == 7) {
	    $info->push_info(0, "DateTime",
			     sprintf("%04d-%02d-%02d %02d:%02d:%02d",
				     unpack("nC5", $data)));
	}
    }
}

1;
