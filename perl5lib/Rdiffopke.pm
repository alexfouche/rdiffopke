###############################
#
# Class:  Rdiffopke
#
###############################

package Rdiffopke;

use Moose;
use Rdiffopke::RepositoryBuilder;
use Rdiffopke::Repository;
use Rdiffopke::FileSourceBuilder;
use Rdiffopke::FileSource;

has 'no_encryption' => ( is => 'rw', isa => 'Bool', default => 0 );
has 'verbose'       => ( is => 'rw', isa => 'Int', default => 0 );
has 'source' =>
  ( is => 'ro', isa => 'Rdiffopke::FileSource', writer => '_set_source' );
has 'source_url' => ( is => 'rw', isa => 'Str', trigger => \&_create_source );
has 'repo_url' => ( is => 'rw', isa => 'Str', )
  ;    # trigger => \&_create_repository ); See comments in this method
has 'repository' =>
  ( is => 'ro', isa => 'Rdiffopke::Repository', writer => '_set_repository' );
has 'version' => ( is => 'ro', isa => 'Num', default => 0.1 );
has 'need_metadata_schema_version' =>
  ( is => 'ro', isa => 'Int', default => 1 );

sub BUILD {
    my $self = shift;

    $self->_set_repository(
        Rdiffopke::RepositoryBuilder->new(
            params => {
                url           => $self->repo_url,
                no_encryption => $self->no_encryption,
                need_metadata_schema_version =>
                  $self->need_metadata_schema_version,
				verbose => $self->verbose,
            }
          )->instance
    );
}

sub _create_source {
    my $self = shift;

    $self->_set_source(
        Rdiffopke::FileSourceBuilder->new(
            params => { url => $self->source_url, verbose => $self->verbose,}
          )->instance
    );
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

    $self->repository->set_message(
        "255 - Repository did not explicitely terminated")
      if ( defined( $self->repository ) );
    $self->repository->close if ( defined $self->repository );
    $self->source->close     if ( defined $self->source );

}

sub compare_files {
   my $self = shift;

	$self->repository->compare_files($self->source->get_detailed_file_list);
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
