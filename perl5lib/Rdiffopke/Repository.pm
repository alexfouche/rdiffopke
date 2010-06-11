###############################
#
# Class:  Rdiffopke::Repository
#
###############################

package Rdiffopke::Repository;

use Moose;
use Rdiffopke::Metadata;
use Rdiffopke::UserKey;
use Rdiffopke::Exception;
use Rdiffopke::SubTypes;

has 'no_encryption' => ( is => 'ro', isa => 'Bool', default  => 0 );
has 'url'           => ( is => 'ro', isa => 'Str',  required => 1 );
has 'need_metadata_schema_version' =>( is => 'ro', isa => 'Int', required => 1 );
#has 'need_metadata_schema_version' =>( is => 'ro', isa => 'PositiveInt', required => 1 ); # TOFIX why is TypeConstraint not working ?
has 'metadata' =>
  ( is => 'ro', isa => 'Rdiffopke::Metadata', writer => '_set_metadata' );
has 'userkey' =>
  ( is => 'ro', isa => 'Rdiffopke::UserKey', writer => '_set_userkey' );
has 'verbose' => ( is => 'rw', isa => 'Int', default => 0 );

sub BUILD {
    my $self = shift;

    if ( ref($self) eq 'Rdiffopke::Repository' ) {
        Rdiffopke::Exception::Repository->throw( error =>
"The Rdiffopke::Repository class is a base virtual class and can not be instanciated\n"
        );
    }
}

# The prepare() of the base class contains checks and create metadata and userkey instances.
# Create a 'before prepare' function in the child class instead of overriding this function,
# and open or create your repository and apply checks depending on the medium/architecture/organisation
# of your repository
sub prepare {
    my $self = shift;

    if ( !$self->userkey_exists && !$self->no_encryption && $self->has_data ) {
        Rdiffopke::Exception::Repository->throw( error =>
"Repository has data inside but is missing the public key file and you requested encryption\n"
        );
    }

    if ( $self->no_encryption && $self->userkey_exists ) {
        Rdiffopke::Exception::Repository->throw( error =>
"You have requested no encryption but there is a public key file\n"
        );
    }

    if (   !$self->no_encryption
        && !$self->userkey_exists
        && $self->metadata->exists )
    {
        Rdiffopke::Exception::Repository->throw( error =>
"There is a metadata file  but the public key file is missing ! Set to 'no encryption' if you never used it there\n"
        );
    }

    $self->_set_metadata(
        Rdiffopke::Metadata->new(
            dbfile     => $self->_get_metadata_dbfile,
            upgrade_to => $self->need_metadata_schema_version,
            verbose    => $self->verbose
        )
    );
    $self->_set_userkey(
        Rdiffopke::UserKey->new(
            key     => $self->_create_get_userkey,
            verbose => $self->verbose
        )
    ) unless ( $self->no_encryption );

    ::verbose_message( "Finished preparing repository at '" . $self->url . "'\n" )
      if ( $self->verbose );
}

sub _get_metadata_dbfile {
    my $self = shift;

    if ( ref($self) eq 'Rdiffopke::Repository' ) {
        Rdiffopke::Exception::Repository->throw( error =>
              "The _get_metadata_dbfile function needs to be overriden\n" );
    }
}

sub _create_get_userkey {
    my $self = shift;

    if ( ref($self) eq 'Rdiffopke::Repository' ) {
        Rdiffopke::Exception::Repository->throw( error =>
              "The '_create_get_userkey' function needs to be overriden\n" );
    }
}

sub set_message {
    my ( $self, $message ) = @_;
    $self->metadata->set_message($message) if ( defined $self->metadata );
}

sub metadata_exists {
    my $self = shift;

    if ( ref($self) eq 'Rdiffopke::Repository' ) {
        Rdiffopke::Exception::Repository->throw(
            error => "The 'userkey_exists' function needs to be overriden\n" );
    }
}

sub userkey_exists {
    my $self = shift;

    if ( ref($self) eq 'Rdiffopke::Repository' ) {
        Rdiffopke::Exception::Repository->throw(
            error => "The 'userkey_exists' function needs to be overriden\n" );
    }
}

sub close {
    my $self = shift;
    $self->metadata->close if ( defined $self->metadata );

    # userkey was already saved at creation time;

# Do an 'after close' in your Repository::_ChildClass, to push back the metadata db file if your Repo is remote
}

sub schema_version {
    my $self = shift;
    return $self->metadata->schema_version if ( defined $self->metadata );
}

sub DEMOLISH {
    $_[0]->close;
}

sub compare_files {
    my $self = shift;
	
	my $source_file_list = $self->source->get_detailed_file_list;
	my $repo_file_list = $self->metadata->get_detailed_file_list;

	$repo_file_list->rewind;
	$source_file_list->rewind;



	while  ( my $file=$detailed_file_list->next ){
		if ($file->is_file) {
			$file->open_r;
			my $buf;
			while ( my $bytes = $file->read($buf, 10)) {
				print "$buf-----";
			}
		}

}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
