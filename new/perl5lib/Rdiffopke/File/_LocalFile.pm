###############################
#
# Class:  Rdiffopke::File::_LocalFile
#
###############################

package Rdiffopke::File::_LocalFile;

use Moose;
use FileHandle;
use Moose::Util::TypeConstraints;

extends 'Rdiffopke::File';

subtype 'PositiveInt'
     => as 'Int'
     => where { $_ > 0 }
     => message { 'Only positive greater than zero integers accepted' };


has 'buffer_read_size' => (is=>'rw', isa=>'PositiveInt', default=>100*1024);

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
            unless ( defined( $self->handle ) ) {
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
            $self->_set_type('link');
            last SWITCH;
        };
        Rdiffopke::Exception::File->throw(
            error => "File type for file " . $self->path . " not supported\n" );
    }
}

override 'read' => sub {
    my ( $self, $buf, $readsize ) = @_;

    unless ( $self->type eq 'file' ) {
        Rdiffopke::Exception::File->throw( error => "The file type for file "
              . $self->path
              . " can not be read\n" );
    }

    my $bytes = $self->handle->read( $buf, $readsize );
    unless ( defined $bytes ) {
        Rdiffopke::Exception::File->throw(
            error => "Error reading file " . $self->path . "\n" );
    }

    return $bytes;
};

override 'close' => sub {
	my $self = shift;
 
    $self->handle->close if ( defined $self->handle );
};

override 'open_r' => sub {
    my $self = shift;

    unless ( $self->type eq 'file' ) {
        Rdiffopke::Exception::File->throw( error => "The file type for file " . $self->path . " can not be opened\n" );
    };

    unless ( $self->handle->open( $self->path, 'r' ) ) {
        Rdiffopke::Exception::File->throw(
            error => "Can not open file " . $self->path . " for reading\n" );
    };
};

no Moose;
__PACKAGE__->meta->make_immutable;

1;
