###############################
#
# Class:  Rdiffopke::FileSource::_Localdir
#
###############################

package Rdiffopke::FileSource::_LocalDir;

use Moose;

extends 'Rdiffopke::FileSource';

# because "after 'new'" does not work
sub BUILD {
      my $self = shift;
	unless ( -d $self->url) { Rdiffopke::Exception::FileSource->throw(error=>"Local directory ". $self->url ." is not recognized"); };
  };



no Moose;
__PACKAGE__->meta->make_immutable;

1;