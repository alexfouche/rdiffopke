
###############################
    #
    # Class:  Rdiffopke::Filelist
    #
###############################

    package Rdiffopke::Filelist;

    sub new {
        return bless {};
    }

    sub add {
        my ( $self, $item ) = shift;

        unless ( defined($item) && $item->isa('Rdiffopke::File') ) {
            $self->{ $item->{path} } = $item;
        }
    }

    1;

