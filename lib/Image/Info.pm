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

    if (my $format = determine_file_format($head)) {
	no strict 'refs';
	my $mod = "Image::Info::$format";
	my $sub = "$mod\::process_file";
	unless (defined &$sub) {
	    eval "require $mod";
	    die $@ if $@;
	    die "$mod did not define &$sub" unless defined &$sub;
	}

	my $info = bless [], "Image::Info::Result";
	&$sub($info, $source, @_);
	$info->clean_up;

	return wantarray ? @$info : $info->[0];
    }
    return;
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
    my($self, $n, $key, $value) = @_;
    push(@{$self->[$n]{$key}}, $value);
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
