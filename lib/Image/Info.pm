package Image::Info;

# Copyright 1999, Gisle Aas.
#
# This library is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

use strict;
use Symbol ();

use vars qw($VERSION @EXPORT_OK);

$VERSION = '0.02';  # $Date$

require Exporter;
*import = \&Exporter::import;

@EXPORT_OK = qw(image_info dim html_dim);

my @magic = (
   "\xFF\xD8" => "JPEG",
   "II*\0"    => "TIFF",
   "MM\0*"    => "TIFF",
   "\x89PNG\x0d\x0a\x1a\x0a" => "PNG",
   "GIF87a" => "GIF",
   "GIF89a" => "GIF",
);

sub image_info
{
    my $source = shift;

    if (!ref $source) {
        require Symbol;
        my $fh = Symbol::gensym();
        open($fh, $source) || return _os_err("Can't open $source");
        binmode($fh);
        $source = $fh;
    }
    elsif (ref($source) eq "SCALAR") {
	return { Error => "Literal image source not supported yet" }
    }
    else {
	seek($source, 0, 0) or return _os_err("Can't rewind");
    }

    my $head;
    read($source, $head, 32) == 32 or return _os_err("Can't read head");
    seek($source, 0, 0) or _os_err("Can't rewind");

    if (my $format = determine_file_format($head)) {
	no strict 'refs';
	my $mod = "Image::Info::$format";
	my $sub = "$mod\::process_file";
	my $info = bless [], "Image::Info::Result";
	eval {
	    unless (defined &$sub) {
		eval "require $mod";
		die $@ if $@;
		die "$mod did not define &$sub" unless defined &$sub;
	    }

	    &$sub($info, $source, @_);
	    $info->clean_up;
	};
	return { Error => $@ } if $@;
	return wantarray ? @$info : $info->[0];
    }
    return { Error => "Unrecognized file format" };
}

sub _os_err
{
    return { Error => "$_[0]: $!",
	     Errno => $!+0,
	   };
}

sub determine_file_format
{
    my $head = shift;
    for (my $i = 0; $i < @magic; $i += 2) {
	my $m = $magic[$i];
	return $magic[$i+1] if substr($head, 0, length($m)) eq $m;
    }
    return;
}

sub dim
{
    my $img = shift || return;
    my $x = $img->{ImageWidth} || return;
    my $y = $img->{ImageLength} || return;
    wantarray ? ($x, $y) : "$x×$y";
}

sub html_dim
{
    my($x, $y) = dim($_);
    return unless $x;
    "WIDTH=$x HEIGHT=$y";
}

package Image::Info::Result;

sub push_info
{
    my($self, $n, $key) = splice(@_, 0, 3);
    push(@{$self->[$n]{$key}}, @_);
}

sub clean_up
{
    my $self = shift;
    for (@$self) {
	for my $k (keys %$_) {
	    my $a = $_->{$k};
	    $_->{$k} = $a->[0] if @$a <= 1;
	}
    }
}

1;
