use 5.008001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Posy::Plugin::Flickr::Photo',
    VERSION_FROM      => 'lib/Posy/Plugin/Flickr/Photo.pm', # finds $VERSION
    PREREQ_PM         => {
      Posy                      => 0.97,
      Posy::Core                => 0.97,
      Posy::Plugin::Cache::File => 0.1,
      Flickr::API               => 0,
      Test::More                => 0,
      XML::XPath                => 0
    }, 
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Posy/Plugin/Flickr/Photo.pm', # retrieve abstract from module
       AUTHOR         => 'blair christensen. <blair@devclue.com>') : ()),
);
