package Image::TIFF;

# Copyright 1999, Gisle Aas.
#
# This library is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

use strict;
use vars qw($VERSION);

$VERSION = '0.01';

my @types = (
  undef,
  [ "BYTE",      "C1", 1],
  [ "ASCII",     "A1", 1],
  [ "SHORT",     "n1", 2],
  [ "LONG",      "N1", 4],
  [ "RATIONAL",  "N2", 8],
  [ "SBYTE",     "c1", 1],
  [ "UNDEFINED", "a1", 1],
  [ "SSHORT",    "n1", 2],
  [ "SLONG",     "N1", 4],
  [ "SRATIONAL", "N2", 8],
  [ "FLOAT",     "f1", 4],  # XXX 4-byte IEEE format
  [ "DOUBLE",    "d1", 8],  # XXX 8-byte IEEE format
);

my %exif_intr_tags = (
    0x1    => "InteroperabilityIndex",
    0x2    => "InteroperabilityVersion",
    0x1000 => "RelatedImageFileFormat",
    0x1001 => "RelatedImageWidth",
    0x1002 => "RelatedImageLength",
);

my %exif_tags = (
    0x828D => "CFARepeatPatternDim",
    0x828E => "CFAPattern",
    0x828F => "BatteryLevel",
    0x8298 => "Copyright",
    0x829A => "ExposureTime",
    0x829D => "FNumber",
    0x83BB => "IPTC/NAA",
    0x8769 => "ExifOffset",
    0x8773 => "InterColorProfile",
    0x8822 => { __TAG__ => "ExposureProgram",
		1 => "Manual",
		2 => "Program",
		3 => "Aperture priority",
		4 => "Shutter priority",
		5 => "Program creative",
		6 => "Program action",
		7 => "Portrait",
		8 => "Landscape",
	      },
    0x8824 => "SpectralSensitivity",
    0x8825 => "GPSInfo",
    0x8827 => "ISOSpeedRatings",
    0x8828 => "OECF",
    0x9000 => "ExifVersion",
    0x9003 => "DateTimeOriginal",
    0x9004 => "DateTimeDigitized",
    0x9101 => "ComponentsConfiguration",
    0x9102 => "CompressedBitsPerPixel",
    0x9201 => "ShutterSpeedValue",
    0x9202 => "ApertureValue",
    0x9203 => "BrightnessValue",
    0x9204 => "ExposureBiasValue",
    0x9205 => "MaxApertureValue",
    0x9206 => "SubjectDistance",
    0x9207 => { __TAG__ => "MeteringMode",
		1 => "Average",
		2 => "Center weighted average",
		3 => "Spot",
		4 => "Multi-spot",
		5 => "Multi-segment",
	      },
    0x9208 => { __TAG__ => "LightSource",
		0 => "Auto",
		1 => "Daylight",
		2 => "Fluorescent",
		3 => "Tungsten",
		10 => "Flash",
	      },
    0x9209 => { __TAG__ => "Flash",
		0 => "No",
		1 => "Yes",
	      },
    0x920A => "FocalLength",
    0x927C => "MakerNote",
    0x9286 => "UserComment",
    0x9290 => "SubSecTime",
    0x9291 => "SubSecTimeOriginal",
    0x9292 => "SubSecTimeDigitized",
    0xA000 => "FlashPixVersion",
    0xA001 => "ColorSpace",
    0xA002 => "ExifImageWidth",
    0xA003 => "ExifImageLength",
    0xA005 => {__TAG__ => "InteroperabilityOffset",
	       __SUBIFD__ => \%exif_intr_tags,
	      },
    0xA20B => "FlashEnergy",                  # 0x920B in TIFF/EP
    0xA20C => "SpatialFrequencyResponse",     # 0x920C    -  -
    0xA20E => "FocalPlaneXResolution",        # 0x920E    -  -
    0xA20F => "FocalPlaneYResolution",        # 0x920F    -  -
    0xA210 => { __TAG__ => "FocalPlaneResolutionUnit",     # 0x9210    -  -
		1 => "dpi",
		2 => "dpm",
		3 => "dpcm",
		4 => "dpmm",
		5 => "dpµm",
	      },
    0xA214 => "SubjectLocation",              # 0x9214    -  -
    0xA215 => "ExposureIndex",                # 0x9215    -  -
    0xA217 => "SensingMethod",                # 0x9217    -  -
    0xA300 => "FileSource",
    0xA301 => "SceneType",
);

my %tiff_tags = (
  255   => { __TAG__ => "SubfileType",
	     1 => "FullResolution",
	     2 => "ReducedResolution",
	     3 => "SinglePage",
	   },
  259   => { __TAG__ => "Compression",
	     1 => "PackBytes",
	     2 => "CCITT Group3",
	     3 => "CCITT T4",
	     4 => "CCITT T6",
	     5 => "LZW",
	     6 => "JPEG",
	     32773 => "PackBits",
           },
  262   => { __TAG__ => "PhotometricInterpretation",
	     0 => "WhiteIsZero",
	     1 => "BlackIsZero",
             2 => "RGB",
	     3 => "RGB Palette",
	     4 => "Transparency Mask",
	     5 => "CMYK",
	     6 => "YCbCr",
	     8 => "CIELab",
	   },
  263   => { __TAG__ => "Threshholding",
	     1 => "NoDithering",
	     2 => "OrderedDither",
	     3 => "Randomized",
	   },
  270   => "ImageDescription",
  271   => "Make",
  272   => "Model",
  273   => "StipOffset",
  274   => { __TAG__ => "Orientation",
	     1 => "top_left",
	     2 => "top_right",
	     3 => "bot_right",
	     4 => "bot_left",
	     5 => "left_top",
	     6 => "right_top",
	     7 => "right_bot",
	     8 => "left_bot",
	   },
  282   => "XResolution",
  283   => "YResolution",
  296   => {__TAG__ => "ResolutionUnit",
	    1 => "pixels", 2 => "dpi", 3 => "dpcm",
	   },
  305   => "Software",
  306   => "DateTime",
  513   => "JPEGInterchangeFormat",
  514   => "JPEGInterchangeFormatLngth",
  531   => "YCbCrPositioning",
  33432 => "Copyright",
  34665 => { __TAG__ => "ExifOffset",
	     __SUBIFD__ => \%exif_tags,
	   },
);


sub new
{
    my $class = shift;
    my $source = shift;

    if (!ref($source)) {
	local(*F);
	open(F, $source) || return;
	binmode(F);
	$source = \*F;
    }

    if (ref($source) ne "SCALAR") {
	# XXX should really only read the file on demand
	local($/);  # slurp mode
	my $data = <$source>;
	$source = \$data;
    }

    my $self = bless { source => $source }, $class;

    for ($$source) {
	my $byte_order = substr($_, 0, 2);
	$self->{little_endian} = ($byte_order eq "II");
	$self->{version} = $self->unpack("n", substr($_, 2, 2));

	my $ifd = $self->unpack("N", substr($_, 4, 4));
	while ($ifd) {
	    push(@{$self->{ifd}}, $ifd);
	    my($num_fields) = $self->unpack("x$ifd n", $_);
	    $ifd = $self->unpack("N", substr($_, $ifd + 2 + $num_fields*12, 4));
	}
    }

    $self;
}

sub unpack
{
    my $self = shift;
    my $template = shift;
    if ($self->{little_endian}) {
	$template =~ tr/nN/vV/;
    }
    CORE::unpack($template, $_[0]);
}

sub num_ifds
{
    my $self = shift;
    scalar @{$self->{ifd}};
}

sub ifd
{
    my $self = shift;
    my $num = shift || 0;
    my @ifd;
    return $self->add_fields($self->{ifd}[$num], \@ifd);
}

sub tagname
{
    $tiff_tags{$_[1]} || "Tag-$_[1]";
}

sub add_fields
{
    my($self, $offset, $ifds, $tags) = @_;
    return unless $offset;
    $tags ||= \%tiff_tags;

    for (${$self->{source}}) {  # alias as $_
	my $entries = $self->unpack("x$offset n", $_);
      FIELD:
	for my $i (0 .. $entries-1) {
	    my($tag, $type, $count, $voff) =
		$self->unpack("nnNN", substr($_, 2 + $offset + $i*12, 12));
	    my $val;
	    if (my $t = $types[$type]) {
		$type = $t->[0];
		my $tmpl = $t->[1];
		my $vlen = $t->[2];
		if ($count * $vlen <= 4) {
		    $voff = 2 + $offset + $i*12 + 8;
		}
		$tmpl =~ s/(\d+)$/$count*$1/e;
		my @v = $self->unpack("x$voff$tmpl", $_);
		$val = (@v > 1) ? \@v : $v[0];

		if ($type =~ /S?RATIONAL$/ && @v == 2 && $val->[1] &&
		    !($val->[0] % $val->[1]))
		{
		    $val = $val->[0]/$val->[1];
		}

	    }
	    $tag = $tags->{$tag} || $self->tagname($tag);

	    if (ref($tag)) {
		die "Assert" unless ref($tag) eq "HASH";
		if (my $sub = $tag->{__SUBIFD__}) {
		    $self->add_fields($val, $ifds, $sub);
		    next FIELD;
		}
		$val = $tag->{$val} if exists $tag->{$val};
		$tag = $tag->{__TAG__};
	    }

	    $self->_push_field($ifds, $tag, $type, $count, $val);
	}
    }
    $ifds;
}

sub _push_field
{
    my $self = shift;
    my $ifds = shift;
    push(@$ifds, [@_]);
}

1;
