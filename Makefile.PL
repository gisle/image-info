require 5.005;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Image::Info',
    VERSION_FROM => 'lib/Image/Info.pm',
    dist         => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);
