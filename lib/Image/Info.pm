package Image::Info;

use strict;
use Symbol ();

use vars qw($VERSION @magic);

@magic = (
   "\xFF\xD8" => "JPEG",
   "II*\0"    => "TIFF",
   "MM\0*"    => "TIFF",
);

sub new
{
    my($class, $source) = @_;

    if (!ref $source) {
        require Symbol;
        my $fh = Symbol::gensym();
        open($fh, $source) || return;
        binmode($fh);
        $source = $fh;
    }
    elsif (ref($source) eq "SCALAR") {
	die;   # literal data not supported yet
    }
    else {
	seek($source, 0, 0) or die;
    }

    my $head;
    read($source, $head, 32) == 32 or die;
    seek($source, 0, 0) or die;

    for (my $i = 0; $i < @magic; $i += 2) {
	my $m = $magic[$i];
	if (substr($head, 0, length($m)) eq $m) {
	    my $self = $class->init_format($magic[$i+1], $source);
	    $self->deref_info_array;
	    return $self;
	}
    }
    #die "Unknown image file format";
    return;
}

sub push_info
{
    my($self, $n, $key, $value) = @_;
    push(@{$self->{"img$n"}{$key}}, $value);
}

sub deref_info_array
{
    my $self = shift;
    while (my($k,$v) = each %$self) {
	next unless $k =~ /^img\d+$/;
	for (keys %$v) {
	    my $a = $v->{$_};
	    $v->{$_} = $a->[0] if @$a <= 1;
	}
    }
}

sub init_format
{
    my($class, $format, $fh) = @_;
    my $fclass = "Image::Info::$format";
    eval "require $fclass";
    die $@ if $@;
    $fclass->new($fh);
}

sub info
{
    my($self, $n) = @_;
    $n ||= 0;
    $self->{"img$n"};
}

1;
