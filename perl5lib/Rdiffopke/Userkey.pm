
###############################
    #
    # Class:  Rdiffopke::Userkey
    #
###############################

    package Rdiffopke::Userkey;

    use base qw(Class::Accessor::Fast );
    Rdiffopke::Userkey->mk_ro_accessors qw( _filename );

    sub new {
        my $class  = shift;
        my %params = @_;
        return unless ( defined $params{dir} );
        return bless {
            error_code => 0,
            _verbose   => $params{verbose},
            _filename  => "$params{dir}/pubkey",
        };

    }

    sub exists {
        my $self = shift;
        ( -e $self->_filename ) ? 1 : 0;
    }

    1;
