package Image::TIFF;

use strict;

my @types = (
  undef,
  [ "BYTE",      "C",  1],
  [ "ASCII",     "A",  1],
  [ "SHORT",     "n",  2],
  [ "LONG",      "N",  4],
  [ "RATIONAL",  "NN", 8],
  [ "SBYTE",     "c",  1],
  [ "UNDEFINE",  "a",  1],
  [ "SSHORT",    "n",  2],
  [ "SLONG",     "N",  4],
  [ "SRATIONAL", "NN", 8],
  [ "FLOAT",     "f",  4],
  [ "DOUBLE",    "d",  8],
);

my %tags = (
  259   => "Compression",
  270   => "ImageDescription",
  271   => "Make",
  272   => "Model",
  273   => "StipOffset",
  274   => "Orientation",
  282   => "XResolution",
  283   => "YResolution",
  296   => "ResolutionUnit",
  305   => "Software",
  306   => "DateTime",
  513   => "JPEGInterchangeFormat",
  514   => "JPEGInterchangeFormatLngth",
  531   => "YCbCrPositioning",
  33432 => "Copyright",
);

sub new
{
    my $class = shift;
    my $source = shift;

    if (!ref($source)) {
	local(*F);
	open(F, $source) || return;
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
    return $self->ifd_entries($self->{ifd}[$num]);
}

sub ifd_entries
{
    my($self, $offset) = @_;
    return unless $offset;

    my @ifd;
    for (${$self->{source}}) {
	my $entries = $self->unpack("x$offset n", $_);
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
		my @v = $self->unpack("x$voff$tmpl$count", $_);
		$val = (@v > 1) ? \@v : $v[0];
	    }

	    $tag = $tags{$tag} || "Tag-$tag";

	    push(@ifd, [$tag, $type, $count, $voff, $val]);
	}
    }
    return \@ifd;
}


1;
