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

has 'dbfile'     => ( is => 'ro', isa => 'Str',         required => 1 );
has 'upgrade_to' => ( is => 'ro', isa => 'Int', required => 1 ); 
#has 'upgrade_to' => ( is => 'ro', isa => 'PositiveInt', required => 1 );  # TOFIX why is TypeConstraint not working ?
has '_dbh'       => ( is => 'rw', isa => 'Maybe[DBI::db]' );
has 'verbose'    => ( is => 'rw', isa => 'Int',        default  => 0 );
has 'rdiff' => ( is => 'ro', isa => 'Int', writer => '_set_rdiff' );    # this is the current rdiff the metadata is dealing with
#has 'rdiff' => ( is => 'ro', isa => 'PositiveInt', writer => '_set_rdiff' ); # TOFIX why is TypeConstraint not working ?
has 'schema_version' =>
  ( is => 'ro', isa => 'Int', writer => '_set_schema_version' );

sub BUILD {
    my $self = shift;

    if ( -e $self->dbfile ) {
        ::verbose_message("Metadata exists, checking schema version")
          if ( $self->verbose );
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
          if ( $self->verbose );
        $self->_connect;
        $self->_set_schema_version(0);
        $self->_upgrade_schema;
        ::verbose_message("Metadata created")
          if ( $self->verbose );
    }
}

sub _connect {
    my $self = shift;

    ::verbose_message("Connecting to metadata")
      if ( $self->verbose );
    my $dbh = DBI->connect( "dbi:SQLite:dbname=" . $self->dbfile, "", "" );
    unless ( defined $dbh ) {
        Rdiffopke::Exception::Metadata->throw( error =>
"Metadata file seems to be corrupted. It should be a SQLite database\n"
        );
    }

    $dbh->{RaiseError} = 1;
    $dbh->{PrintError} = 0;
#    $dbh->do("PRAGMA foreign_keys = ON");
#    $dbh->do("PRAGMA default_synchronous = OFF");

    $self->_dbh($dbh);
}

sub _disconnect {
    my $self = shift;

    ::verbose_message("Disconnecting metadata")
      if ( $self->verbose );
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
	retrieval_date datetime not null, owner text, "group" text, mode text, mdate datetime not null, type text not null, size integer not null );',
'create table paths (path_id integer primary key autoincrement not null, path text not null);',
'create table localfiles (localfile_id integer primary key autoincrement not null, path text not null, size integer not null, key_id integer);',
'create table keys ( key_id integer primary key autoincrement not null, key blob not null);',
'insert into options values("metadata_version", 1);',
        ],
    );

    ::verbose_message("Metadata schema needs upgrade, do not interrupt...")
      if ( $self->verbose );

    for ( my $i = $self->schema_version +1 ; $i <= $self->upgrade_to ; $i++ ) {

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
        $self->_set_schema_version ( $i);
    }

    ::verbose_message("Finished upgrade of metadata schema")
      if ( $self->verbose );
}

sub set_message {
    my ( $self, $message ) = @_;

    $self->_dbh->do(
        "update rdiffs set message = $message where rdiff = " . $self->rdiff )
      if ( $self->rdiff && defined( $self->_dbh ) );

}

sub get_detailed_file_list {
	    my $self = shift;

	    my $file_list = Rdiffopke::FileList->new;
$DB::single=1;	
		my $sql_rows;
		eval {
			$sql_rows = $self->_dbh->selectall_arrayref( 'select file_id, paths.path, localfiles.path, owner, "group", mode, mdate, files.size from files, paths, localfiles where files.path_id=paths.path_id and files.localfile_id=localfiles.localfile_id;');
		};if($@) {
			Rdiffopke::Exception::Metadata->throw(
                error => "An error occurred selecting file list from metadata:\n"
                  . $self->_dbh->errstr );
        };

		foreach ( @$sql_rows) {
				$file_list->add($_->[1],
	                Rdiffopke::File::_LocalFile->new(
	                    file_id => $_->[0],
	                    orig_path => $_->[1],
						path => $_->[2],
	                   	 uid  =>$_->[3],
					 	gid  => $_->[4],
					mode =>$_->[5],
	   mtime => $_->[6],                  
	 size => $_->[7],
	                ) );
			}
			
			return  $file_list;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
