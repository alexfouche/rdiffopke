###############################
#
# Class:  Rdiffopke::FileSource
#
###############################

package Rdiffopke::FileSource;

use Moose;

has 'url' => ( is => 'ro', isa => 'Str', required => 1 );

sub BUILD {
	my $self=shift;
	
    if (ref($self) eq 'Rdiffopke::FileSource' ){Rdiffopke::Exception::FileSource->throw( error =>
"The 'Rdiffopke::FileSource' class is a base virtual class and can not be instanciated\n"
    );}
}

sub prepare {
}

sub get_detailed_file_list {
    Rdiffopke::Exception::FileSource->throw(
        error => "The 'get_detailed_file_list' function should be overridden\n" );
}

sub close {}

sub DEMOLISH {
	$_[0]->close;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
