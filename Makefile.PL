require 5.004;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME     => 'Image::Exif',
    VERSION  => '0.01',
    dist     => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);
