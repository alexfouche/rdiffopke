
###############################
    #
    # Class:  Rdiffopke::File::_Localfile
    #
###############################

    package Rdiffopke::File::_Localfile;

    use base qw( FileHandle);

    sub new {
        my ( $class, %params ) = @_;
$DB::single = 1;
        unless ( defined( $params{path} ) ) {
            die "the Rdiffopke needs a path";
        }
		   unless ( -r $params{path} ) {
	            die "File is not readable";
	        }

my $self = bless {};
  $self->mode( $params{mode} );
    $self->path( $params{path} );
    $self->uid( $params{uid} );
    $self->gid( $params{gid} );
    $self->size( $params{size} );
    $self->mtime( $params{mtime} );
    $self->mode( $params{mode} );


	        if ( -f $self->path) {
		$self->type('file');
	      $self->_file ( FileHandle->new);
	        unless ( defined($self->_file) ) { die "failure to create filehandle"; }   
	
	
	} elsif (-d $self->path) {
		$self->type('dir');
	} else {
		die "File type not supported";
	}
	
}
   

   

    sub open_r {
        my $self = shift;
unless ($self->_type eq 'file') {die "This filetype does not support open()"}

        unless ( $self->_file->open( $self->path, 'r' ) ) {
            die "Can not open the file";
        }
    }

    sub read {
        my ( $self, $buf, $readsize ) = @_;

		unless ($self->_type eq 'file') {die "This filetype does not support open()"}

        my $bytes = $self->_file->read( $buf, $readsize );
        unless ( defined $bytes ) { die "Error reading file"; }
        return $bytes;

    }

    sub close {
        my $self = shift;
        $self->_file->close;

    }

    sub mark_as_processed {
        my $self = shift;
        $self->{_processed} = 1;

    }

    sub processed {
        my $self = shift;
        return $self->{_processed};
    }

    1;
