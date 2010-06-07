
###############################
    #
    # Class:  Rdiffopke::Filesource::_Localdir
    #
###############################

    package Rdiffopke::Filesource::_Localdir;

    use base qw( Rdiffopke::Filesource Class::Accessor::Fast );
    Rdiffopke::Filesource::_Localdir->mk_ro_accessors qw(  _dir);

    sub new {
        my $class  = shift;
        my %params = @_;
        return unless ( defined $params{dir} );

        return bless {
            _verbose   => $params{verbose},
            _dir       => $params{dir},
        };
    }

    sub prepare {
        my $self = shift;

    }

    sub get_detailed_file_list {
        my $self = shift;

$DB::single = 1;
        my $file_list = Rdiffopke::Filelist->new;

        my $dir = Path::Class::Dir->new( $self->_dir )->absolute;

        $dir->recurse(
            callback => sub {
                my $thing = shift;
                my $stat  = $thing->lstat;
                $file_list->add(
                    Rdiffopke::File::_Localfile->new(
                        path  => "$thing",
                        mode  => $stat->mode,
                        uid   => $stat->uid,
                        gid   => $stat->gid,
                        size  => $stat->size,
                        mtime => scalar( gmtime( $stat->mtime ) ),
                        type  => ( $thing->is_dir ) ? 'dir' : 'file',
                    )
                  )

            }
        );

        return $file_list;
    }

1;