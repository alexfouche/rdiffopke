###############################
#
# Class:  Rdiffopke::Repository::_LocalDir
#
###############################

package Rdiffopke::Repository::_LocalDir;

use Moose;
use Rdiffopke::Exception;

extends 'Rdiffopke::Repository';

has '_userkey_file' =>
  ( is => 'ro', isa => 'Str', writer => '_set_userkey_file' );
has '_metadata_dbfile' =>
  ( is => 'ro', isa => 'Str', writer => '_set_metadata_dbfile' );

# because "after 'new'" does not work
sub BUILD {
    my $self = shift;

    # Stupid, we create the directory in prepare() if it does not exist
    #    unless ( -d $self->url ) {
    #        Rdiffopke::Exception::Repository->throw(
    #            error => "Local directory " . $self->url . " does not exist" );
    #    }

    $self->_set_userkey_file( $self->url . '/pubkey' );
    $self->_set_metadata_dbfile( $self->url . '/metadata' );
}

before 'prepare' => sub {
    my $self = shift;

    ::verbose_message(
        "Checking and initializing rdiff repository '" . $self->url . "'" )
      if ( $self->verbose );

    if ( -e $self->url && !-d $self->url ) {
        Rdiffopke::Exception::Repository->throw(
            error => "The local rdiff repository '" .$self->url
              . "' already exists and is not a directory\n" );
    }
    else {
        mkdir $self->url;
    }

    unless ( -d $self->url
        && -x $self->url
        && -w $self->url )
    {
        Rdiffopke::Exception::Repository->throw(
            error => "Directory '". $self->url
              . "' is neither writable nor browseable\n" );
    }
};

sub has_data {
    my $self = shift;
    my $tmp  = $self->url . "/data";
    return (<$tmp/*>) && 1;
}

override 'userkey_exists' => sub {
    my $self = shift;
    return ( -e $self->_userkey_file );
};

override 'metadata_exists' => sub {
    my $self = shift;
    return ( -e $self->_metadata_file );
};

override '_create_get_userkey' => sub {
    my $self = shift;

    Rdiffopke::Exception::Repository->throw(
        error => "TODO __PACKAGE__ __LINE__\n" );

    # TODO
    #get the key if it exists
    # create the key if it does not exists
    # save the key in file
    # close the file
};

override '_get_metadata_dbfile' => sub {
    my $self = shift;
    return $self->_metadata_dbfile;
};

no Moose;
__PACKAGE__->meta->make_immutable;

1;
