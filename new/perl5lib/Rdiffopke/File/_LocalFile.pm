###############################
#
# Class:  Rdiffopke::File::_LocalFile
#
###############################

package Rdiffopke::File::_LocalFile;

use Moose;
#use Moose::Util::TypeConstraints;
use FileHandle;
#use IO::Handle '_IOFBF';

extends 'Rdiffopke::File';

# Does not fucking work, see http://stackoverflow.com/questions/3011880/perl-mooseutiltypeconstraints-bug-what-is-this-error-about-the-name-has-inv
#subtype 'PositiveInt'
# 	 =>	as 'Int'
#     => where { $_ >0 }
#     => message { 'Only positive greater than zero integers accepted' };

#has 'buffer_read_size' => (is=>'rw', isa=>'PositiveInt', default=>100*1024);
has 'buffer_read_size' => (is=>'rw', isa=>'Int', default=>100*1024);

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
            $self->_set_type('slink');
            last SWITCH;
        };
        Rdiffopke::Exception::File->throw(
            error => "File type for file " . $self->path . " not supported\n" );
    }
}

override 'read' => sub {
    my $self = $_[0];  # Do not modify @_, to use the trick at http://stackoverflow.com/questions/3011653/what-is-the-magic-behind-perl-read-function-and-buffer-which-is-not-a-ref
 	my $readsize  = $_[2];

	$readsize = $self->buffer_read_size unless (defined $readsize);

	$DB::single=1;
    unless ( $self->type eq 'file' ) {
        Rdiffopke::Exception::File->throw( error => "The file type for file "
              . $self->path
              . " can not be read\n" );
    }

    my $bytes = $self->handle->read( $_[1], $readsize );
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
	
#	$self->handle->setvbuf($buffer, _IOFBF, 0x10000);
};

no Moose;
__PACKAGE__->meta->make_immutable;

1;
