package Image::TIFF;

use strict;

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
	local($/);  # slurp mode
	my $data = <$source>;
	$source = \$data;
    }

    my $self = bless {}, $class;

    for ($$source) {
	my $byte_order = substr($_, 0, 2);
	$self->{little_endian} = ($byte_order eq "II");
	$self->{version} = $self->unpack("n", substr($_, 2, 2));

	my $ifd = $self->unpack("N", substr($_, 4, 4));
	while ($ifd) {
	    my($num_fields) = $self->unpack("n", substr($_, $ifd, 2));
	    push(@{$self->{ifd}}, [$ifd, $num_fields]);
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

1;
