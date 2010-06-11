###############################
#
# Class:  Rdiffopke::Metadata
#
###############################

package Rdiffopke::Metadata;

use Moose;

has 'dbfile' =>(is=>'ro', isa=>'Str', required=>1);
has 'upgrade_to'=>(is=>'ro', isa=>'Int', required=>1)
has 


sub _disconnect {
    my $self = shift;

    $self->_dbh->disconnect;
    $self->{_dbh} = undef;
}

sub close{
    my $self = shift;
     $self->_disconnect;
     $self->error_code(0);
}

sub DEMOLISH {
	my $self=shift;
	$self->close;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;