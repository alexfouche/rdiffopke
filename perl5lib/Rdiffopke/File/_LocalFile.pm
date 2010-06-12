###############################
#
# Class:  Rdiffopke::File::_LocalFile
#
###############################

package Rdiffopke::File::_LocalFile;

use Moose;
use FileHandle;
use Rdiffopke::SubTypes;
#use IO::Handle '_IOFBF';

extends 'Rdiffopke::File';

has 'buffer_read_size' =>( is => 'rw', isa => 'Int', default => 100 * 1024 );
#has 'buffer_read_size' => (is=>'rw', isa=>'PositiveInt', default=>100*1024); # TOFIX why is TypeConstraint not working ?
has '_handle' =>
  ( isa => 'Maybe[FileHandle]', is => 'ro', writer => '_create_handle' );

sub BUILD {
    my $self = shift;

    unless ( $self->path ) {
        Rdiffopke::Exception::File->throw(
            error => "File " . $self->path . "is not readable\n" );
    }

  SWITCH: {
        -f $self->path && do {
            $self->_set_type('file');
            $self->_create_handle( FileHandle->new );
            unless ( defined( $self->_handle ) ) {
                Rdiffopke::Exception::File->throw(
                        error => "Could not create handle for file "
                      . $self->path
                      . "\n" );
            }
            last SWITCH;
        };
        -d $self->path && do {
            $self->_set_type('dir');
            last SWITCH;
        };
        -l $self->path && do {
            $self->_set_type('slink');
            last SWITCH;
        };

# TOFIX : uncomment this. It was commented just for a test
#        Rdiffopke::Exception::File->throw(
#            error => "File type for file " . $self->path . " not supported\n" );
    }
}

override 'read' => sub {
    my $self = $_[0]
      ; # Do not modify @_, to use the trick at http://stackoverflow.com/questions/3011653/what-is-the-magic-behind-perl-read-function-and-buffer-which-is-not-a-ref
    my $readsize = $_[2];

    $readsize = $self->buffer_read_size unless ( defined $readsize );

    unless ( $self->type eq 'file' ) {
        Rdiffopke::Exception::File->throw( error => "The file type for file "
              . $self->path
              . " can not be read\n" );
    }

    my $bytes = $self->_handle->read( $_[1], $readsize );
    unless ( defined $bytes ) {
        Rdiffopke::Exception::File->throw(
            error => "Error reading file " . $self->path . "\n" );
    }

    return $bytes;
};

override 'close' => sub {
    my $self = shift;

    $self->_handle->close if ( defined $self->_handle );
};

override 'open_r' => sub {
    my $self = shift;

    unless ( $self->type eq 'file' ) {
        Rdiffopke::Exception::File->throw( error => "The file type for file "
              . $self->path
              . " can not be opened\n" );
    }

    unless ( $self->_handle->open( $self->path, 'r' ) ) {
        Rdiffopke::Exception::File->throw(
            error => "Can not open file " . $self->path . " for reading\n" );
    }

    #	$self->_handle->setvbuf($buffer, _IOFBF, 0x10000);
};

no Moose;
__PACKAGE__->meta->make_immutable;

1;
