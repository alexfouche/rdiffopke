
###############################
#
# Class:  Rdiffopke
#
###############################

package Rdiffopke;

use Moose;
use Rdiffopke::Repository;
use Rdiffopke::Filesource;

has 'no_encryption' => ( is => 'rw', isa => 'Bool', default => 0 );
has 'verbose'       => ( is => 'rw', isa => 'Bool', default => 0 );
has 'source'     => ( is => 'rw', isa => 'Rdiffopke::Filesource', );
has 'source_url' => ( is => 'rw', isa => 'Str' );
has 'repo_url'   => ( is => 'rw', isa => 'Str' );
has 'repository' => ( is => 'rw', isa => 'Rdiffopke::Repository', );
has 'version'    => ( is => 'ro', isa => 'Num', default => 0.1 );
has 'need_metadata_schema_version' =>
  ( is => 'need_metadata_schema_version', isa => 'Int', default => 1 );

sub import_required_modules {
    my @modules =
      qw( Moose Getopt::Std DBI DBD::SQLite Path::Class FileHandle  );

    # File::Path::Hashed Path::Class Path::Class::File Path::Class::Dir
    my @messages = ();

    foreach (@modules) {
        eval "use $_";
        push @messages, $_ if ($@);
    }

    if (@messages) {
        print STDERR
          "Some Perl modules are missing for rdiffopke to run. Missing:\n";
        print STDERR "$_\n" foreach (@messages);
        exit 1;
    }
}

sub get_params_and_input {
    my $self    = shift;
    my $getopts = {};

    getopts( 'vu:p:d:s:ic:x', $getopts ) or die '8';

    $self->verbose(1) if ( $getopts->{v} );
    $self->no_encryption( $getopts->{x} );
    $self->source( $getopts->{s} );
    $self->repo_url( $getopts->{d} );

    unless ( $self->source && $self->repo_url ) {
        die '8';
    }

}

sub init_repository {
    my $self = shift;

    $self->repository(
        Rdiffopke::Repository->new(
            dir                 => $self->repo_url,
            verbose             => $self->verbose,
            no_encryption       => $self->no_encryption,
            upgrade_metadata_to => $self->need_metadata_schema_version
        )
    );

    !$self->repository->init;

}

sub prepare_source {
    my $self = shift;

    $self->source( Rdiffopke::Filesource->new( url => $self->source_url ) );
    $self->source->prepare;

}

sub proceed {
    my $self = shift;

    $self->repository->proceed( $self->source->get_detailed_file_list );

}

sub terminate {
    my ( $self, $code, $message ) = @_;

    $self->repository->set_message("${code}- $message")
      if ( defined($code) && defined( $self->repository ) );

    $self->repository->close if ( defined $self->repository );
    exit 0;
}

sub quit_error {
    my ( $self, $error_code, @messages ) = @_;

    my %errors = (
        1 => "Some Perl modules are missing for rdiffopke to run.\n",
        2 =>
          "'$self->rdiff_dir' is neither writable nor browseable -> aborting",
        3 =>
"'$self->rdiff_dir' has files inside but is missing the public key file -> aborting",

#        3 =>
# "'$self->rdiff_dir' has files inside but is missing the public key file '${self->repository->userkey->filename}' -> aborting",
        4 =>
"You have requested no encryption but there is a public key file -> aborting",

#        4 =>
# "You have requested no encryption but there is a public key file '${self->repository->userkey->filename}' -> aborting",
        5 =>
"There is a metadata file  but the public key file is missing ! Set to 'no encryption' if you never used it there -> aborting",

#        5 =>
#"There is a metadata file '$self->repository->metadata->filename' but the public key file '${self->repository->userkey->filename}' is missing ! Set to 'no encryption' if you never used it there -> aborting",
        6 =>
"Metadata file seems to be corrupted. It should #be a SQLite database -> aborting",

#        6 =>
# "Metadata file '${self->repository->metadata->filename}' seems to be corrupted. It should #be a SQLite database -> aborting",
        7 => "An error occurred while initializing metadata file -> aborting",

#        7 =>
#"An error occurred while initializing metadata '${self->repository->metadata->filename}' file -> aborting",
        8 =>
"Usage: $0 [-v] [-u <username>] [-p <password>] [-x] [-c <credentials_file>] [-i] -s <source> -d <local_destination_dir>

-i read credentials from stdin

-l list increments

-x disable encryption
delete increments

-? size opke key
-? size blowfish key
-? size read buffer
-? nb threads (default no threads)
thorough verify


il faudrait une option pour tout verifier

Note:
Source only support local directory or ftp:// at this time",
        9 => "Could not read metadata version from metadata file -> aborting",

#        9 =>
# "Could not read metadata version from metadata file '$self->repository->metadata->filename' -> aborting",
        10 => "Killed (SIGTERM)",
        11 => "Aborted by user (SIGINT)",
        12 => "The local rdiff '$self->rdiff_dir' is not a directory",
        13 => "An error occurred during user key creation",
        14 => "An error occurred while upgrading metadata schema",
        15 =>
"The parameter given to tell_which_files_needed() is not a Rdiffopke::Filelist instance",

    );

    $DB::single = 1;
    print STDERR localtime(time) . "   $errors{$error_code}\n";
    foreach (@messages) {
        print STDERR localtime(time) . "   $_\n";
    }

    $self->terminate( $error_code, $errors{$error_code} );
}

no Moose;
__PACKAGE__->meta->make_immutable;
