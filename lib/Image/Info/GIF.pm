package Image::Info::GIF;

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

sub read_data_blocks
{
    my $source = shift;
    my @data;
    while (my $len = ord(my_read($source, 1))) {
	push(@data, my_read($source, $len));
    }
    join("", @data);
}


sub process_file
{
    my($info, $fh) = @_;

    my $header = my_read($fh, 13);
    die "Bad GIF signature"
	unless $header =~ s/^GIF(8[79]a)//;
    my $version = $1;
    $info->push_info(0, "GIF_Version" => $version);

    # process logical screen descriptor
    my($sw, $sh, $packed, $bg, $aspect) = unpack("vvCCC", $header);
    $info->push_info(0, "ScreenWidth" => $sw);
    $info->push_info(0, "ScreenHeight" => $sh);

    my $color_table_size = 1 << (($packed & 0x07) + 1);
    $info->push_info(0, "ColorTableSize" => $color_table_size);

    $info->push_info(0, "SortedColors" => ($packed & 0x08) ? 1 : 0)
	if $version eq "89a";

    $info->push_info(0, "ColorResolution", (($packed & 0x70) >> 4) + 1);

    my $global_color_table = $packed & 0x80;
    $info->push_info(0, "GlobalColorTableFlag" => $global_color_table ? 1 : 0);
    if ($global_color_table) {
	$info->push_info(0, "BackgroundColor", $bg);
    }

    if ($aspect) {
	$info->push_info(0, "PixelAspectRatio" => ($aspect + 15) / 64);
    }

    # more??
    my $color_table = my_read($fh, $color_table_size * 3);
    #$info->push_info(0, "GlobalColorTable", [unpack("C" . $color_table_size * 3, $color_table)]);

    my $img_no = 0;

    while (1) {
	my $intro = ord(my_read($fh, 1));
	if ($intro == 0x3B) {  # trailer
	    return;
	}
	elsif ($intro == 0x2C) {  # new image
	    my($x_pos, $y_pos, $w, $h, $packed) =
		unpack("vvvvC", my_read($fh, 9));
	    $info->push_info($img_no, "XPos", $x_pos);
	    $info->push_info($img_no, "YPos", $y_pos);
	    $info->push_info($img_no, "ImageWidth", $w);
	    $info->push_info($img_no, "ImageLength", $h);

	    if ($packed & 0x80) {
		# yes, we have a local color table
		my $ct_size = 1 << ($packed & 0x07 + 1);
		$info->push_info($img_no, "LColorTableSize" => $ct_size);
		my $color_table = my_read($fh, $ct_size * 3);
	    }

	    $info->push_info($img_no, "Interlaced" =>
			     ($packed & 0x040) ? 1 : 0);

	    my $lzw_code_size = ord(my_read($fh, 1));
	    $info->push_info($img_no, "LZW_MininmCodeSize", $lzw_code_size);
	    read_data_blocks($fh);  # skip image data
	    $img_no++;
	}
	elsif ($version eq "89a" && $intro == 0x21) {  # GIF89a extension
	    my $label = ord(my_read($fh, 1));
	    my $data = read_data_blocks($fh);
	    $info->push_info($img_no, "L-$label" => $data);
	}
	else {
	    die "Unknown introduced code $intro, bad GIF";
	}
    }
}

1;
