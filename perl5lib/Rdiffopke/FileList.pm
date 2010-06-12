###############################
#
# Class:  Rdiffopke::Filelist
#
###############################

package Rdiffopke::FileList;

sub new {
	return bless {};
}

sub add {
    # my ( $self, $key, $item ) = @_;
	$_[0]->{$_[1]} = $_[2] if ( defined($_[2])&& $_[2]->isa('Rdiffopke::File'));
}

sub delete{
	delete $_[0]->{$_[1]};
}

1;
