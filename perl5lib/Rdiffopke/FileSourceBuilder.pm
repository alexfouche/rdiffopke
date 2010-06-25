###############################
#
# Class:  Rdiffopke::FileSourceBuilder
#
###############################

package Rdiffopke::FileSourceBuilder;

use Moose;
use Rdiffopke::FileSource::_LocalDir;
use Rdiffopke::Exception;

has 'params' => ( is => 'ro', isa => 'HashRef', required => 1 );

sub instance {
    my $self = shift;

    $_ = $self->params->{url};
SWITCH: {
        /^file:\/\//
            && do { $self->params->{url} = $self->params->{url} =~ s-^file://--; last SWITCH; };
        /^sftp:\/\// && do { last SWITCH; };
        /^ftp:\/\//  && do { last SWITCH; };
    }

    # If we did not returned yet, maybe it is a local directory
    if ( -d $self->params->{url} ) {
        return Rdiffopke::FileSource::_LocalDir->new( %{ $self->params } );
    }

    # We should never get there
    Rdiffopke::Exception::FileSource->throw(
        error => "Source URL '" . $self->params->{url} . "' is not recognized" );
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
