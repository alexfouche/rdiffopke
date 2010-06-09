###############################
#
# Class:  Rdiffopke::FileSource
#
###############################

package Rdiffopke::FileSource;

use Moose;

has 'url'       => ( is => 'ro', isa => 'Str', required => 1 );

sub prepare {
}

sub get_detailed_file_list {
    Rdiffopke::Exception::FileSource->throw (error=>"The get_detailed_file_list function should be overwritten");
}

no Moose;
__PACKAGE__->meta->make_immutable;
