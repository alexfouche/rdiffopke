###############################
#
# Class:  Rdiffopke
#
###############################

package Rdiffopke;

my $verbose;

use Moose;
use Rdiffopke::RepositoryBuilder;
use Rdiffopke::Repository;
use Rdiffopke::FileSourceBuilder;
use Rdiffopke::FileSource;

has 'no_encryption'    => ( is => 'rw', isa => 'Bool',                  default => 0 );
has 'need_verify_repo' => ( is => 'rw', isa => 'Bool',                  default => 0 );
has 'source'           => ( is => 'ro', isa => 'Rdiffopke::FileSource', writer  => '_set_source' );
has 'source_url' => ( is => 'rw', isa => 'Str', trigger => \&_create_source );
has 'repo_url' => ( is => 'rw', isa => 'Str', )
    ;    # trigger => \&_create_repository ); See comments in this method
has 'repository' => (
    is     => 'ro',
    isa    => 'Rdiffopke::Repository',
    writer => '_set_repository'
);
has 'version'                      => ( is => 'ro', isa => 'Num',  default => 0.1 );
has 'verbose'                      => ( is => 'ro', isa => 'Int',  default => 0 );
has 'need_metadata_schema_version' => ( is => 'ro', isa => 'Int',  default => 1 );
has 'want_rdiffbackup'             => ( is => 'ro', isa => 'Bool', default => 0 );

#has '_source_file_list' =>( is => 'ro', isa => 'Rdiffopke::FileList' );

sub BUILD {
    my $self = shift;

    $Rdiffopke::verbose = $self->verbose;

    $self->_set_repository(
        Rdiffopke::RepositoryBuilder->new(
            params => {
                url                          => $self->repo_url,
                no_encryption                => $self->no_encryption,
                need_metadata_schema_version => $self->need_metadata_schema_version,
                source_url => $self->source_url,    # For informational purposes only, but required
                want_rdiffbackup => $self->want_rdiffbackup,
            }
            )->instance
    );
}

sub _create_source {
    my $self = shift;

    $self->_set_source(
        Rdiffopke::FileSourceBuilder->new( params => { url => $self->source_url, } )->instance );
}

sub prepare_source {
    my $self = shift;
    $self->source->prepare;
}

sub _create_repository {
    my $self = shift;

    # We can not create repository here because this method is called by trigger
    # and requires attribute need_metadata_schema_version which might not yet be set
    # so in BUILD instead
    #    $self->_set_repository(
    #        Rdiffopke::Repository->new(
    #            url                 => $self->repo_url,
    #            no_encryption       => $self->no_encryption,
    #            upgrade_metadata_to => $self->need_metadata_schema_version
    #        )
    #    );
}

sub prepare_repository {
    my $self = shift;
    $self->repository->prepare;
}

sub terminate {
    my ( $self, $code, $message ) = @_;

    $self->repository->set_message("$code - $message")
        if ( defined($code) && defined( $self->repository ) );

    $self->repository->close;
    $self->source->close;

}

sub DEMOLISH {
    my $self = shift;

    $self->repository->set_message("255 - Repository did not explicitely terminated")
        if ( defined( $self->repository ) );
    $self->repository->close if ( defined $self->repository );
    $self->source->close     if ( defined $self->source );

}

sub compare_files {
    my $self = shift;

    #	$self->_source_file_list($self->source->get_detailed_file_list);
    #	$self->repository->compare_files($self->_source_file_list);
    $self->repository->compare_files( $self->source->get_detailed_file_list )
        ; # Since the compare_files() will generate lists which are in facts lists of instances of the source Rdiffopke::File, we do not need to keep the detailed file list from source
}

sub transfer_files {
    my $self = shift;

    # $self->repository->transfer_files($self->_source_file_list);
    $self->repository->transfer_files
        ; # Since the compare_files() will generate lists which are in facts lists of instances of the source Rdiffopke::File, we do not need to keep the detailed file list from source
}

sub verify_repo {
    my $self = shift;
    $self->repository->prepare unless ( defined $self->repository->metadata );
    $self->repository->verify;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
