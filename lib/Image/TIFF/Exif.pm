package Image::TIFF::Exif;

# Copyright 1999, Gisle Aas.
#
# This library is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

use strict;
use vars qw(@ISA);

require Image::TIFF;
@ISA = qw(Image::TIFF);

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
    0x8822 => "ExposureProgram",
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
    0x9207 => "MeteringMode",
    0x9208 => "LightSource",
    0x9209 => "Flash",
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
    0xA005 => "InteroperabilityOffset",
    0xA20B => "FlashEnergy",                  # 0x920B in TIFF/EP
    0xA20C => "SpatialFrequencyResponse",     # 0x920C    -  -
    0xA20E => "FocalPlaneXResolution",        # 0x920E    -  -
    0xA20F => "FocalPlaneYResolution",        # 0x920F    -  -
    0xA210 => "FocalPlaneResolutionUnit",     # 0x9210    -  -
    0xA214 => "SubjectLocation",              # 0x9214    -  -
    0xA215 => "ExposureIndex",                # 0x9215    -  -
    0xA217 => "SensingMethod",                # 0x9217    -  -
    0xA300 => "FileSource",
    0xA301 => "SceneType",
);

my %intr_tags = (
    0x1    => "InteroperabilityIndex",
    0x2    => "InteroperabilityVersion",
    0x1000 => "RelatedImageFileFormat",
    0x1001 => "RelatedImageWidth",
    0x1002 => "RelatedImageLength",
);

my %sub_ifds = (
    "Tag-34665" => \%exif_tags,
    InteroperabilityOffset => \%intr_tags,
);

sub _push_field
{
    my $self = shift;
    if (my $o = $sub_ifds{$_[1]}) {
	my($ifds, $tag, $type, $count, $val) = @_;
	$self->add_fields($val, $ifds, $o);
    }
    else {
	return $self->SUPER::_push_field(@_);
    }
}

1;
