###############################
#
# Class:  Rdiffopke::File::_LocalFile
#
###############################

package Rdiffopke::File::_LocalFile;

use Moose;
use FileHandle;
use Path::Class;
#use IO::Handle '_IOFBF';

extends 'Rdiffopke::File';

has '_handle' => ( isa => 'Maybe[FileHandle]', is => 'ro', writer => '_create_handle' );

sub BUILD {
    my $self = shift;

    unless ( defined( $self->{type} )
        && ( $self->{type} eq 'file' || $self->{type} eq 'dir' || $self->{type} eq 'slink' ) )
    {
        unless ( -e $self->path ) {
            Rdiffopke::Exception::File->throw(
                error => "File " . $self->path . "is not readable\n" );
        }

    SWITCH: {
            -l $self->path && do {
                $self->_set_type('slink');
                my $target = readlink( $self->path );
 
                unless ( defined $target ) {
                    Rdiffopke::Exception::File->throw(
                              error => "Could not extract the target from symlink "
                            . $self->path
                            . "\n" );
                }
                $self->target($target);

                last SWITCH;
            };
            -f $self->path && do {
                $self->_set_type('file');
                $self->_create_handle( FileHandle->new );
                unless ( defined( $self->_handle ) ) {
                    Rdiffopke::Exception::File->throw(
                        error => "Could not create handle for file " . $self->path . "\n" );
                }
                last SWITCH;
            };
            -d $self->path && do {
                $self->_set_type('dir');
                last SWITCH;
            };

            Rdiffopke::Exception::File->throw(
                error => "File type for file " . $self->path . " not supported\n" );
        }
    }
}

# Params: self, buffer, readsize
override 'read' => sub {
    my $self = $_[0]
        ; # Do not modify @_, to use the trick at http://stackoverflow.com/questions/3011653/what-is-the-magic-behind-perl-read-function-and-buffer-which-is-not-a-ref
    my $readsize = $_[2];

    $readsize = 100 * 1024 unless ( defined $readsize );

    unless ( defined $self->_handle ) {
        Rdiffopke::Exception::File->throw(
            error => "File handle not defined for '" . $self->path . "' \n" );
    }

    my $bytes = $self->_handle->read( $_[1], $readsize );
    unless ( defined $bytes ) {
        Rdiffopke::Exception::File->throw( error => "Error reading file " . $self->path . "\n" );
    }

    return $bytes;
};

override 'close' => sub {
    my $self = shift;

    $self->_handle->close if ( defined $self->_handle );
};

override 'open_r' => sub {
    my $self = shift;

    unless ( $self->is_file ) {
        Rdiffopke::Exception::File->throw(
            error => "The file type for file '" . $self->path . "' can not be opened\n" );
    }

    unless ( $self->_handle->open( $self->path, 'r' ) ) {
        Rdiffopke::Exception::File->throw(
            error => "Can not open file '" . $self->path . "' for reading\n" );
    }

    #	$self->_handle->setvbuf($buffer, _IOFBF, 0x10000);
};

no Moose;
__PACKAGE__->meta->make_immutable;

1;
