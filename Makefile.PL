require 5.004;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Image::Info',
    VERSION_FROM => 'lib/Image/Info.pm',
    dist         => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);
