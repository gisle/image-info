package Image::Info::PNG;

# Copyright 1999, Gisle Aas.
#
# This library is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

use strict;

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

    $info->push_info(0, "FileMediaType" => "image/png");
    $info->push_info(0, "FileExt" => "png");

    my @chunks;

    while (1) {
        my($len, $type) = unpack("Na4", my_read($fh, 8));

	if (@chunks) {
	    my $last = $chunks[-1];
	    $last =~ s/\s(\d+)$//;
	    my $count = $1 || 1;
	    if ($last eq $type) {
		$count++;
		$chunks[-1] = "$type $count";
	    }
	    else {
		push(@chunks, $type);
	    }
	}
	else {
	    push(@chunks, $type);
	}

        last if $type eq "IEND";
        my $data = my_read($fh, $len + 4);
	my $crc = unpack("N", substr($data, -4, 4, ""));
	if ($type eq "IHDR" && $len == 13) {
	    my($w, $h, $depth, $ctype, $compression, $filter, $interlace) =
		unpack("NNCCCCC", $data);
	    $ctype = {
		      0 => "Gray",
		      2 => "RGB",
		      3 => "Indexed-RGB",
		      4 => "GrayA",
		      6 => "RGBA",
		     }->{$ctype} || $ctype;

	    $compression = "Deflate" if $compression == 0;
	    $filter = "Adaptive" if $filter == 0;
	    $interlace = "Adam7" if $interlace == 1;

	    $info->push_info(0, "ImageWidth", $w);
	    $info->push_info(0, "ImageHeight", $h);
	    $info->push_info(0, "BitsPerSample", $depth);
	    $info->push_info(0, "ColorType", $ctype);
	    $info->push_info(0, "Compression", $compression);
	    $info->push_info(0, "PNG_Filter", $filter);
	    $info->push_info(0, "Interlace", $interlace)
		if $interlace;
	}
	elsif ($type eq "PLTE") {
	    my @table;
	    while (length $data) {
		push(@table, sprintf("#%02x%02x%02x",
				     unpack("C3", substr($data, 0, 3, ""))));
	    }
	    $info->push_info(0, "RGB_Palette" => \@table);
	}
	elsif ($type eq "gAMA" && $len == 4) {
	    $info->push_info(0, "Gamma", unpack("N", $data)/100_000);
	}
	elsif ($type eq "pHYs" && $len == 9) {
	    my($res_x, $res_y, $unit) = unpack("NNC", $data);
	    if (0 && $unit == 1) {
		# convert to dpi
		$unit = "dpi";
		for ($res_x, $res_y) {
		    $_ *= 0.0254;
		}
	    }
	    $info->push_info(0, "XResolution" => $res_x);
	    $info->push_info(0, "YResolution" => $res_y);
	    if ($unit) {
		$unit = "dpm" if $unit == 1;
		$info->push_info(0, "ResolutionUnit" => $unit);
	    }
	}
	elsif ($type eq "tEXt") {
	    my($key, $val) = split(/\0/, $data, 2);
	    # XXX should make sure $key is not in conflict with any
	    # other key we might generate
	    $info->push_info(0, $key, $val);
	}
	elsif ($type eq "tIME" && $len == 7) {
	    $info->push_info(0, "LastModificationTime",
			     sprintf("%04d-%02d-%02d %02d:%02d:%02d",
				     unpack("nC5", $data)));
	}
    }

    $info->push_info(0, "PNG_Chunks", @chunks);
}

1;
