package Image::TIFF;

use strict;

my @types = (
  undef,
  [ "BYTE",      "C1", 1],
  [ "ASCII",     "A1", 1],
  [ "SHORT",     "n1", 2],
  [ "LONG",      "N1", 4],
  [ "RATIONAL",  "N2", 8],
  [ "SBYTE",     "c1", 1],
  [ "UNDEFINE",  "a1", 1],
  [ "SSHORT",    "n1", 2],
  [ "SLONG",     "N1", 4],
  [ "SRATIONAL", "N2", 8],
  [ "FLOAT",     "f1", 4],
  [ "DOUBLE",    "d1", 8],
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

my %codes = (
  ResolutionUnit => { 1 => "pixels", 2 => "dpi", 3 => "dpcm"},
  Orientation => { 1 => "top_left",
		   2 => "top_right",
		   3 => "bot_right",
		   4 => "bot_left",
		   5 => "left_top",
		   6 => "right_top",
		   7 => "right_bot",
		   8 => "left_bot",
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
    $tags{$_[1]} || "Tag-$_[1]";
}

sub add_fields
{
    my($self, $offset, $ifds, $override_tags) = @_;
    return unless $offset;
    $override_tags ||= {};

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
		$tmpl =~ s/(\d+)$/$count*$1/e;
		my @v = $self->unpack("x$voff$tmpl", $_);
		$val = (@v > 1) ? \@v : $v[0];
	    }
	    my $tag = $override_tags->{$tag} || $self->tagname($tag);

	    if (my $c = $codes{$tag}) {
		$val = $c->{$val} if exists $c->{$val};
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
