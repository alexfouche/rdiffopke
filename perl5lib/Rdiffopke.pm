
###############################
#
# Class:  Rdiffopke
#
###############################

package Rdiffopke;

use base qw(Class::Accessor::Fast );
Rdiffopke->mk_accessors(
    qw( repository no_encryption source rdiff_dir verbose ));
Rdiffopke->mk_ro_accessors(qw( version need_metadata_schema_version ));

sub import_required_modules {
    my @modules =
      qw( Class::Accessor Class::Accessor::Fast Getopt::Std DBI DBD::SQLite Path::Class FileHandle  );

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

sub new {
    return bless {
        version                      => 0.1,
        need_metadata_schema_version => 1,
        no_encryption                => 0
    };
}

sub get_params_and_input {
    my $self    = shift;
    my $getopts = {};

    getopts( 'vu:p:d:s:ic:x', $getopts ) or quit_error(8);

    $self->verbose(1) if ( $getopts->{v} );
    $self->no_encryption( $getopts->{x} );
    $self->source( $getopts->{s} );
    $self->rdiff_dir( $getopts->{d} );

    unless ( $self->source && $self->rdiff_dir ) {
        $DB::single = 1;
        $self->quit_error(8);
    }

}

sub init_repository {
    my $self = shift;

    $self->repository(
        Rdiffopke::Repository->new(
            dir                 => $self->rdiff_dir,
            verbose             => $self->verbose,
            no_encryption       => $self->no_encryption,
            upgrade_metadata_to => $self->need_metadata_schema_version
        )
    );
    if ( !$self->repository->init ) {
        $self->quit_error( $self->repository->error_code );
    }

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

sub prepare_source {
   my $filesource = Rdiffopke::Filesource->new( url => $self->source );
	$filesource->prepare;
	
}

sub proceed {
    my $self = shift;

 
    $self->repository->proceed( $filesource->get_detailed_file_list);

}

1;

