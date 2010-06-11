

    sub init {
        my $self   = shift;
        my %params = @_;

        if ( -e $self->_filename ) {

            unless ( $self->_connect ) {
                return 0;    # $self->error_code is already set
            }

            eval {
                local $self->_dbh->{RaiseError} = 1;
                local $self->_dbh->{PrintError} = 0;
                $DB::single = 1;
                $self->schema_version(
                    $self->_dbh->selectrow_array(
'select value from options where name = "metadata_version";'
                    )
                );
            };
            if ($@) {
                $self->error_code(9);
                return 0;
            }
            unless ( defined( $self->schema_version )
                && $self->schema_version > 0 )
            {
                $self->error_code(9);
                return 0;
            }

            $self->_upgrade_schema_to( $params{upgrade_metadata_to} )
              if ( $self->schema_version < $params{upgrade_metadata_to} );

        }
        else {
            unless ( $self->_connect ) {
                return 0;    # $self->error_code is already set
            }
            $self->{schema_version} = 0;
        }

        local $self->_dbh->{PrintError} = 0;

        $self->_dbh->do("PRAGMA foreign_keys = ON");
        $self->_dbh->do("PRAGMA default_synchronous = OFF");

        if (   $params{upgrade_metadata_to}
            && $self->schema_version < $params{upgrade_metadata_to} )
        {
            unless ( $self->_upgrade_schema_to( $params{upgrade_metadata_to} ) )
            {
                return 0;    # $self->error_code is already set
            }

        }

        return 1;            # Returns true
    }

   
    sub _connect {
        my $self = shift;

        my $dbh = DBI->connect( "dbi:SQLite:dbname=$self->_filename", "", "" );
        unless ( defined $dbh ) {
            $self->error_code(6);
            return 0;
        }

        $self->{_dbh} = $dbh;
        return 1;    # Returns true
    }


    sub _upgrade_schema_to {
        my $self       = shift;
        my $upgrade_to = shift;

        my %db_schema_versions = (
            1 => [
'create table diffs (diff integer primary key not null, date_begin datetime not null, date_end datetime not null, message text);',
'create table options (name text primary key not null, value text);',
'create table files (file_id integer primary key autoincrement not null, diff integer not null, path_id integer not null, localfile_id integer,
	retrieval_date datetime not null, owner text, "group" text, mode text, mdate datetime not null, type text not null, size integer not null, target text );',
'create table paths (path_id integer primary key autoincrement not null, path text not null);',
'create table localfiles (localfile_id integer primary key autoincrement not null, path text not null, size integer not null, key_id integer);',
'create table keys ( key_id integer primary key autoincrement not null, key blob not null);',
            ],
        );

        verbose_message("Metadata schema needs upgrade, do not interrupt...")
          if ( $self->_verbose );

        for ( my $i = $self->schema_version + 1 ; $i <= $upgrade_to ; $i++ ) {

            eval {
                local $self->_dbh->{RaiseError} = 1;
                local $self->_dbh->{PrintError} = 0;
                $self->_dbh->begin_work;
                foreach ( @{ $db_schema_versions{$i} } ) {
                    $DB::single = 1;
                    $self->_dbh->do($_);
                }
                $self->_dbh->do(
"update options set value = $i where name = 'metadata_version';"
                );
            };
            if ($@) {
                $self->_dbh->rollback;
                $self->error_code(14);
                return 0;
            }
            else {
                $self->_dbh->commit;
                $self->{schema_version} = $i;

            }
        }

        verbose_message("Finished upgrade of metadata schema")
          if ( $self->_verbose );

        return 1;    # Returns true
    }

    sub set_message {
        my ( $self, $message ) = @_;

        $DB::single = 1;
        $self->_dbh->do(
            "update diffs set message = $message where diff = ${self->diff};")
          if ( $self->diff );

    }

    1;
