###############################
#
# Class:  Rdiffopke::Metadata
#
###############################

package Rdiffopke::Metadata;

use Moose;
use DBI;
use Try::Tiny;
use Rdiffopke::Exception;
use Rdiffopke::SubTypes;

has 'dbfile'     => ( is => 'ro', isa => 'Str', required => 1 );
has 'upgrade_to' => ( is => 'ro', isa => 'Int', required => 1 );

#has 'upgrade_to' => ( is => 'ro', isa => 'PositiveInt', required => 1 );  # TOFIX why is TypeConstraint not working ?
has '_dbh' => ( is => 'rw', isa => 'Maybe[DBI::db]' );
has 'rdiff' => ( is => 'ro', isa => 'Int', writer => '_set_rdiff' )
  ;    # this is the current rdiff the metadata is dealing with
has 'prev_rdiff' => ( is => 'ro', isa => 'Int', writer => '_set_prev_rdiff' )
  ;    # this is the previous rdiff the metadata (normally rdiff-1)

#has 'rdiff' => ( is => 'ro', isa => 'PositiveInt', writer => '_set_rdiff' ); # TOFIX why is TypeConstraint not working ?
has 'schema_version' =>
  ( is => 'ro', isa => 'Int', writer => '_set_schema_version' );

sub BUILD {
    my $self = shift;

    if ( -e $self->dbfile ) {
        ::verbose_message("Metadata exists, checking schema version")
          if ($Rdiffopke::verbose);
        $self->_connect;
        try {
            $self->_set_schema_version(
                $self->_dbh->selectrow_array(
                    'select value from options where name = "metadata_version";'
                )
            );
        }
        catch {
            Rdiffopke::Exception::Metadata->throw(
                error => "Could not read metadata version from metadata file:\n"
                  . $self->_dbh->errstr );
        };
        unless ( defined( $self->schema_version )
            && $self->schema_version > 0 )
        {
            Rdiffopke::Exception::Metadata->throw(
                error => "Could not read metadata version from metadata file:\n"
                  . $self->_dbh->errstr );
        }

        $self->_upgrade_schema if ( $self->schema_version < $self->upgrade_to );
    }
    else {
        ::verbose_message("Metadata does not exist, creating...")
          if ($Rdiffopke::verbose);
        $self->_connect;
        $self->_set_schema_version(0);
        $self->_upgrade_schema;
        ::verbose_message("Metadata created")
          if ($Rdiffopke::verbose);
    }

    $self->_set_current_rdiff;
}

sub _set_current_rdiff {
    my $self = shift;

    # Get the current rdiff number in metadata
    my $rdiff = undef;
    try {
        $rdiff = $self->_dbh->selectrow_array('select max(rdiff) from rdiffs;');
    }
    catch {
        Rdiffopke::Exception::Metadata->throw(
            error => "Could not read latest rdiff number from metadata file:\n"
              . $self->_dbh->errstr );
    };
    ( defined $rdiff ) ? $self->_set_rdiff($rdiff) : $self->_set_rdiff(0);
}

sub add_rdiff {
    my $self = shift;

    # Get the current rdiff if we do not have it
    unless ( defined $self->rdiff ) { $self->_set_current_rdiff }

    $self->_set_prev_rdiff( $self->rdiff );

    # Add a new rdiff number in metadata
    try {
        $self->_dbh->begin_work;
        $self->_dbh->do(
            "insert into rdiffs(rdiff, date_begin, date_end, message) values("
              . ( $self->prev_rdiff + 1 ) . ", '"
              . scalar( gmtime(time) )
              . "','', 'Adding new rdiff' );" );
    }
    catch {
        $self->_dbh->rollback;
        Rdiffopke::Exception::Metadata->throw(
            error => "An error occurred while adding new rdiff\n"
              . $self->_dbh->errstr );
    };
    $self->_dbh->commit;

    # Quick verification the new rdiff was inserted in DB
    $self->_set_current_rdiff;
    unless ( $self->rdiff == $self->prev_rdiff + 1 ) {
        Rdiffopke::Exception::Metadata->throw( error =>
"An error occurred while updating metadata, the new rdiff number was not added !\n"
        );
    }
}

sub elevate_files_to_last_rdiff {
    my $self = shift;

    # Increment all files of previous rdiff to current(new) rdiff
    try {
        $self->_dbh->begin_work;
        $self->_dbh->do( "update files set rdiff="
              . $self->rdiff
              . " where rdiff="
              . $self->prev_rdiff
              . ";" );
    }
    catch {
        $self->_dbh->rollback;
        Rdiffopke::Exception::Metadata->throw( error =>
              "An error occurred while updating rdiffs for files in metadata\n"
              . $self->_dbh->errstr );
    };
    $self->_dbh->commit;
}

sub _connect {
    my $self = shift;

    ::verbose_message("Connecting to metadata")
      if ($Rdiffopke::verbose);
    my $dbh = DBI->connect( "dbi:SQLite:dbname=" . $self->dbfile, "", "" );
    unless ( defined $dbh ) {
        Rdiffopke::Exception::Metadata->throw( error =>
"Metadata file seems to be corrupted. It should be a SQLite database\n"
        );
    }

    $dbh->{RaiseError} = 1;
    $dbh->{PrintError} = 0;
    $dbh->do("PRAGMA foreign_keys = ON");
    $dbh->do("PRAGMA default_synchronous = OFF");

    $self->_dbh($dbh);
}

sub _disconnect {
    my $self = shift;

    ::verbose_message("Disconnecting metadata")
      if ($Rdiffopke::verbose);
    $self->_dbh->disconnect;
    $self->_dbh(undef);
}

sub close {
    $_[0]->_disconnect;
}

sub DEMOLISH {
    $_[0]->close;
}

sub _upgrade_schema {
    my $self = shift;

    my %db_schema_versions = (
        1 => [
'create table rdiffs (rdiff integer primary key not null, date_begin datetime not null, date_end datetime not null, message text);',
'create table options (name text primary key not null, value text);',
'create table files (file_id integer primary key autoincrement not null, rdiff integer not null, path_id integer not null, localfile_id integer,
	retrieval_date datetime not null, uid text, gid text, mode text, mtime datetime not null, type text not null, size integer not null );',
'create table paths (path_id integer primary key autoincrement not null, path text not null);',
'create table localfiles (localfile_id integer primary key autoincrement not null, path text not null, mtime datetime not null, size integer not null, key_id integer);',
'create table keys ( key_id integer primary key autoincrement not null, key blob not null);',
            'insert into options values("metadata_version", 1);',
        ],
    );

    ::verbose_message("Metadata schema needs upgrade, do not interrupt...")
      if ($Rdiffopke::verbose);

    for ( my $i = $self->schema_version + 1 ; $i <= $self->upgrade_to ; $i++ ) {

        try {
            $self->_dbh->begin_work;
            foreach ( @{ $db_schema_versions{$i} } ) {
                $self->_dbh->do($_);
            }
            $self->_dbh->do(
                "update options set value = $i where name = 'metadata_version';"
            );
        }
        catch {
            $self->_dbh->rollback;
            Rdiffopke::Exception::Metadata->throw(
                error => "An error occurred while upgrading metadata schema:\n"
                  . $self->_dbh->errstr );
        };
        $self->_dbh->commit;
        $self->_set_schema_version($i);
    }

    ::verbose_message("Finished upgrade of metadata schema")
      if ($Rdiffopke::verbose);
}

sub set_message {
    my ( $self, $message ) = @_;

    try {
        $self->_dbh->do( "update rdiffs set message = '$message' where rdiff = "
              . $self->rdiff )
          if ( $self->rdiff && defined( $self->_dbh ) );
    }catch {
        Rdiffopke::Exception::Metadata->throw(
            error => "An error occurred while setting message to metadata:\n"
              . $self->_dbh->errstr );
    }

}

sub get_detailed_file_list {
    my $self = shift;

    my $rdiff = $self->rdiff;

    my $file_list = Rdiffopke::FileList->new;
    my ($sql_rows_files, $sql_rows_others);
    eval {
	    # All the files (has a join on table 'localfiles')
        $sql_rows_files = $self->_dbh->selectall_arrayref(
"select file_id, paths.path, localfiles.path, uid, gid, mode, files.mtime, files.size, type from files, paths, localfiles where rdiff=$rdiff and files.path_id=paths.path_id and files.localfile_id=localfiles.localfile_id and files.type = 'file' ;");
        $sql_rows_others = $self->_dbh->selectall_arrayref(
"select file_id, paths.path, null, uid, gid, mode, files.mtime, files.size, type from files, paths 
where rdiff=$rdiff and files.path_id=paths.path_id and files.type != 'file' ;"
        );
    };if($@) {
        Rdiffopke::Exception::Metadata->throw(
            error => "An error occurred selecting file list from metadata:\n"
              . $self->_dbh->errstr );
    };

    foreach (@$sql_rows_files, @$sql_rows_others) {
        $file_list->add(
            $_->[1],
            Rdiffopke::File::_LocalFile->new(
                file_id  => $_->[0],
                rel_path => $_->[1]
                ,    # represents the relative path on the source
                path  => $_->[2],    # is the path of the file in the repository
                uid   => $_->[3],
                gid   => $_->[4],
                mode  => $_->[5],
                mtime => $_->[6],
                size  => $_->[7],
				type  => $_->[8],
            )
        );
    }

    return $file_list;
}

# push modified metadata  to previous rdiff
# try/catch and DB transactional part are managed by the caller
sub _discard_file_metadata {
    my $self = shift;
    my $file = shift;    # Should be a Rdiffopke::File

    my ( $file_id, $path_id );
    if ( defined $file->file_id ) {
        $file_id = $file->file_id;

        # We need to return the path_id
        $path_id = $self->_dbh->selectrow_array("select path_id from files where file_id=$file_id;" );
    }
    else {

# Get the file_id, should return only one record, otherwise indicates a problem in metadata
        ( $file_id, $path_id ) = $self->_dbh->selectrow_array(
"select file_id, files.path_id from files, paths where files.path_id=paths.path_id and path='"
              . $file->rel_path
              . "' and rdiff="
              . $self->rdiff
              . ";" );
    }

	# If $file_id is undef, it probably means that the file is new
	if(!defined $file_id){ return;}

    # Update the record to belong to previous revision
    $self->_dbh->do( "update files set rdiff=" . $self->prev_rdiff    . ", uid='" . $file->uid . "', gid='"  . $file->gid   . "', mode='"  . $file->mode     . "', mtime='" . $file->mtime  . "', type='"   . $file->type  . "', size="    . $file->size . " where file_id=$file_id;" );
	$self->_dbh->do( "update files set rdiff=" . $self->prev_rdiff ." where file_id=$file_id;" );
    return $path_id;
}

# Add a new file metadata, meaning a new record in 'files' table
# try/catch and DB transactional part are managed by the caller
sub _add_file_metadata {
    my $self    = shift;
    my $file    = shift;    # Should be a Rdiffopke::File
    my $path_id = shift
      ; # An optional path_id to be given instead of creating a new record in 'paths' table
    my $localfile = shift
      ; # localfile is a small array [localpath, 'mtime', 'size'], needed if we want to insert a file transferred to repository

$DB::single=1;
    unless ( defined $path_id ) {

# If the path does not already exists, add a path entry in database
# If it is not performant, we should put the path directly in the 'files' table.
# There is no schema constraint to have the path separated in the 'paths' table, just that i though
# it would take less space in DB if we have a lot of long paths and a lot of file changes between runs of rdiffopke
 $path_id = $self->_dbh->selectrow_array( 'select max(path_id) from paths where path="'. $file->rel_path  . '" ;' );
	  unless ($path_id) {
        $self->_dbh->do( "insert into paths(path) values('" . $file->rel_path . "');" );
 			$path_id = $self->_dbh->selectrow_array( 'select max(path_id) from paths where path="'. $file->rel_path  . '" ;' );
      unless ($path_id) {
             Rdiffopke::Exception::Metadata->throw(error => "Could not add a path_id in metadata\n" );
}
        }
    }

	# We are given a 'localfiles' table record structure, let's create it and put the reference in the 'files' record
    my $localfile_id;
    if ( defined $localfile && $file->is_file ) {

        # First add a localfile entry in database
        $self->_dbh->do( 'insert into localfiles(path, mtime, size) values("'
              . $localfile->[0] . '", "'
              . $localfile->[1] . '",'
              . $localfile->[2]
              . ');' );
        $localfile_id = $self->_dbh->selectrow_array(
                'select max(localfile_id) from localfiles where path="'
              . $localfile->[0]
              . '";' );
        unless ($localfile_id) {
            Rdiffopke::Exception::Metadata->throw(
                error => "Could not add a localfile in metadata\n" );
        }
    }

    my ( $localfile_id_string1, $localfile_id_string2 ) = ( '', '' );
    if ($localfile_id) {
        $localfile_id_string1 = "localfile_id,";
        $localfile_id_string2 = "$localfile_id , ";
    }


    $self->_dbh->do(
"insert into files(rdiff, path_id, $localfile_id_string1 uid, gid, mode, mtime, type, size, retrieval_date) values("
          . $self->rdiff . ","
          . $path_id
          . ", $localfile_id_string2 " . "'"
          . $file->uid . "','"
          . $file->gid . "','"
          . $file->mode . "','"
          . $file->mtime . "','"
          . $file->type . "',"
          . $file->size
          . ",'');" );
}

# push modified metadata and file content (localfiles table record) to previous rdiff
sub discard_file {
    my $self = shift;
    my $file = shift;    # Should be a Rdiffopke::File

	my $path_id;
    eval {
        $self->_dbh->begin_work;

        # Discard the file metadata to previous revision
        $path_id= $self->_discard_file_metadata($file);

        # There is nothing to do for the file content (localfiles table)
    }
    ;if($@) {
        $self->_dbh->rollback;
        Rdiffopke::Exception::Metadata->throw(
            error => "Error occurred while updating metadata:\n"
              . $self->_dbh->errstr );
    };
    $self->_dbh->commit;

	return $path_id;
}

# push modified metadata to previous rdiff and replace with a new one
sub replace_file_metadata {
    my $self = shift;
    my $file = shift;    # Should be a Rdiffopke::File

    try {
        $self->_dbh->begin_work;

        # Discard the file metadata to previous rdiff
        my $path_id = $self->_discard_file_metadata($file);

        # add a new the file metadata to current rdiff with same $path_id
        $self->_add_file_metadata($file, $path_id);
    }
    catch {
        $self->_dbh->rollback;
        Rdiffopke::Exception::Metadata->throw(
            error => "Error occurred while updating metadata:\n"
              . $self->_dbh->errstr );
    };
    $self->_dbh->commit;
}

# recreate update metadata and associate reference to a new file in repository
sub add_file {
    my $self = shift;
    my $file = shift;    # Should be a Rdiffopke::File
    my $localfile =
      shift;    # localfile is a small array [localpath, 'mtime', 'size', optional path_id]

    eval {
        $self->_dbh->begin_work;

        # Discard the file metadata to previous rdiff
		# Commented because it is already done in the caller Repository->transfer_files()
        # my $path_id = $self->_discard_file_metadata($file);

        # add a new the file metadata to current rdiff
        # $self->_add_file_metadata( $file, $path_id, $localfile );
        $self->_add_file_metadata( $file, $localfile->[3], $localfile );
    }
    ;if($@) {
        $self->_dbh->rollback;
        Rdiffopke::Exception::Metadata->throw(
            error => "Error occurred while updating metadata:\n"
              . $self->_dbh->errstr );
    };
    $self->_dbh->commit;

}

sub verify {
    my $self = shift;

}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
