###############################
#
# Class:  Rdiffopke::UserKey
#
###############################

package Rdiffopke::UserKey;

use Moose;
use Rdiffopke::Exception;

has 'key' => ( is => 'ro', isa => 'Any', required => 1 );

no Moose;
__PACKAGE__->meta->make_immutable;

1;
