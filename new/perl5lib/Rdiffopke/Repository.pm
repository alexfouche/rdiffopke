###############################
#
# Class:  Rdiffopke::Repository
#
###############################

package Rdiffopke::Repository;

use Moose;
use Rdiffopke::Metadata;
use Rdiffopke::UserKey;
use Rdiffopke::Exception::Repository;

has 'no_encryption' => ( is => 'ro', isa => 'Bool', default => 0 );
has 'url'   => ( is => 'ro', isa => 'Str', required=>1 );
has 'need_metadata_schema_version' => ( is => 'ro', isa => 'Int', required=>1 );
has 'metadata' =>(is=>'ro', isa=>'Rdiffopke::Metadata', writer=>'_create_metadata');
has 'userkey'  =>(is=>'ro', isa=>'Rdiffopke::UserKey', writer=>'_create_userkey');

sub BUILD {
	my $self=shift;
	
    if (ref($self) eq 'Rdiffopke::Repository' ){Rdiffopke::Exception::Repository->throw( error =>
"The Rdiffopke::Repository class is a base virtual class and can not be instanciated\n"
    );}
}

# The prepare() of the base class contains checks and create metadata and userkey instances.
# Create a 'before prepare' function in the child class instead of overriding this function,
# and open or create your repository and apply checks depending on the medium/architecture/organisation
# of your repository
sub prepare { 
	my $self=shift;	
	
	 if ( !$self->userkey_exists && !$self->_no_encryption && $self->has_data ) {
   		Rdiffopke::Exception::Repository->throw( error =>
	"Repository has data inside but is missing the public key file and you requested encryption\n"
	    );}
        
if ($self->no_encryption && $self->userkey_exists) {
       	Rdiffopke::Exception::Repository->throw( error =>
	"You have requested no encryption but there is a public key file\n"
	    );}

		if (!$self->no_encryption && !$self->userkey_exists && $self->metadata->exists) {
		       	Rdiffopke::Exception::Repository->throw( error =>
			"There is a metadata file  but the public key file is missing ! Set to 'no encryption' if you never used it there\n"
			    );}
	
	$self->_create_metadata(Rdiffopke::Metadata->new(dbfile=>$self->_get_metadata_dbfile, upgrade_to => $self->need_metadata_schema_version) ) ;
	$self->_create_userkey(Rdiffopke::UserKey->new(key=>_create_get_userkey)) unless($self->no_encryption);
}

sub _get_metadata_dbfile {
	my $self=shift;
	
    if (ref($self) eq 'Rdiffopke::Repository' ){Rdiffopke::Exception::Repository->throw( error =>
"The _get_metadata_dbfile function needs to be overriden\n"
    );}	
}

sub _create_get_userkey {
	my $self=shift;
	
    if (ref($self) eq 'Rdiffopke::Repository' ){Rdiffopke::Exception::Repository->throw( error =>
"The '_create_get_userkey' function needs to be overriden\n"
    );}	
}


sub set_message {
    my ( $self, $message ) = @_;
    $self->metadata->set_message($message) if ( defined $self->metadata );
}

sub metadata_exists {
    my $self = shift;
   
	    if (ref($self) eq 'Rdiffopke::Repository' ){Rdiffopke::Exception::Repository->throw( error =>
	"The 'userkey_exists' function needs to be overriden\n"
	    );}
}

sub userkey_exists {
    my $self = shift;
   
	    if (ref($self) eq 'Rdiffopke::Repository' ){Rdiffopke::Exception::Repository->throw( error =>
	"The 'userkey_exists' function needs to be overriden\n"
	    );}
}

sub close {
	my $self=shift;
	$self->metadata->close if ( defined $self->metadata );
	# userkey was already saved at creation time;
}

sub schema_version {
	my $self=shift;
      return $self->metadata->schema_version if ( defined $self->metadata );
  }

sub DEMOLISH {
	$self->close;	
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;