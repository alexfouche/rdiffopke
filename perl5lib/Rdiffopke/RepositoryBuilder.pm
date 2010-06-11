###############################
#
# Class:  Rdiffopke::RepositoryBuilder
#
###############################

package Rdiffopke::RepositoryBuilder;

use Moose;
use Rdiffopke::Repository::_LocalDir;
use Rdiffopke::Exception;

has 'params' => ( is => 'ro', isa => 'HashRef', required => 1 );

sub instance {
    my $self = shift;

    $_ = $self->params->{url};
  SWITCH: {
        /^file:\/\//
          && do { $self->params->{url}= $self->params->{url} =~ s-^file://--  ; last SWITCH; };
        /^sftp:\/\// && do { last SWITCH; };
        /^ftp:\/\//  && do { last SWITCH; };
    }

    # If we did not returned yet, we assume a local directory (which might not exist)
 	return Rdiffopke::Repository::_LocalDir->new( %{ $self->params } );

    # We should never get there
    Rdiffopke::Exception::Repository->throw(
        error => "Repository URL '".$self->params->{url} ."' is not recognized" );
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
