###############################
#
# Class:  Rdiffopke::Repository::_LocalDir
#
###############################

package Rdiffopke::Repository::_LocalDir;

use Moose;
use Rdiffopke::Exception;
use File::Copy;
use Path::Class;
use FileHandle;

extends 'Rdiffopke::Repository';

has '_userkey_file' =>
  ( is => 'ro', isa => 'Str', writer => '_set_userkey_file' );
has '_metadata_dbfile' =>
  ( is => 'ro', isa => 'Str', writer => '_set_metadata_dbfile' );

# because "after 'new'" does not work
sub BUILD {
    my $self = shift;

    # Stupid, we create the directory in prepare() if it does not exist
    #    unless ( -d $self->url ) {
    #        Rdiffopke::Exception::Repository->throw(
    #            error => "Local directory " . $self->url . " does not exist" );
    #    }

    $self->_set_userkey_file( $self->url . '/pubkey' );
    $self->_set_metadata_dbfile( $self->url . '/metadata' );
}

before 'prepare' => sub {
    my $self = shift;

    ::verbose_message(
        "Checking and initializing rdiff repository '" . $self->url . "'" )
      if ( $self->verbose );

    if ( -e $self->url && !-d $self->url ) {
        Rdiffopke::Exception::Repository->throw(
                error => "The local rdiff repository '"
              . $self->url
              . "' already exists and is not a directory\n" );
    }
    else {
        mkdir $self->url;
    }

    unless ( -d $self->url
        && -x $self->url
        && -w $self->url )
    {
        Rdiffopke::Exception::Repository->throw( error => "Directory '"
              . $self->url
              . "' is neither writable nor browseable\n" );
    }
};

sub has_data {
    my $self = shift;
    my $tmp  = $self->url . "/data";
    return (<$tmp/*>) && 1;
}

override 'userkey_exists' => sub {
    my $self = shift;
    return ( -e $self->_userkey_file );
};

override 'metadata_exists' => sub {
    my $self = shift;
    return ( -e $self->_metadata_file );
};

override '_create_get_userkey' => sub {
    my $self = shift;

    Rdiffopke::Exception::Repository->throw(
        error => "TODO __PACKAGE__ __LINE__\n" );

    # TODO
    #get the key if it exists
    # create the key if it does not exists
    # save the key in file
    # close the file
};

override '_get_metadata_dbfile' => sub {
    my $self = shift;
    return $self->_metadata_dbfile;
};

# See the Rdiffopke::Repository::_move_files_to_last_rdiff() description in base class
override '_move_files_to_last_rdiff' => sub {
    my $self = shift;

    # nothing to do if the previous rdiff is 0 (the repository is new)
    return if ( $self->metadata->prev_rdiff == 0 );

    my $prev_rdiff_dir = $self->url . "/data/" . $self->metadata->prev_rdiff;
    my $rdiff_dir      = $self->url . "/data/" . $self->metadata->rdiff;

# Fail if there is already a directory named after the current(new) rdiff number
    if ( -d $rdiff_dir ) {
        Rdiffopke::Exception::Repository->throw( error =>
"Directory '$rdiff_dir' should not already exist in the repository\n"
        );
    }

    # Fail if the previous rdiff directory is missing
    unless ( -d $prev_rdiff_dir ) {
        Rdiffopke::Exception::Repository->throw( error =>
"Previous rdiff directory '$prev_rdiff_dir' is missing from the repository\n"
        );
    }

    unless ( rename $prev_rdiff_dir, $rdiff_dir ) {
        Rdiffopke::Exception::Repository->throw( error =>
"Can not rename '$rdiff_dir' should not already exist in the repository\n"
        );
    }

# Create a symlink for convenience if users want to browse the repository. Some platforms do not support symlinks
    try {
        unlink( $self->url . "/latest_rdiff" );
        unlink( $self->url . "/data/_latest_rdiff" );
        symlink "/data/" . $self->metadata->rdiff, $self->url . "/latest_rdiff";
        symlink "/data/" . $self->metadata->rdiff,
          $self->url . "/data/_latest_rdiff";
    };
};

# See the Rdiffopke::Repository::... description in base class
override '_discard_file' => sub {
    my $self = shift;
    my $file = shift;    # Should be a Rdiffopke::File

    unless ( $file->is_file ) {
        Rdiffopke::Exception::Repository->throw( error =>
"Can not discard other file types than 'file' from the repository:\n"
        );
    }

    # First we recreate the original arborescence in the previous rdiff dir
    my $file_name = file( $file->rel_path );
    my $base_dir =
      dir(  $self->url 
          . "/data/"
          . $self->metadata->rdiff . '/'
          . $file_name->dir->stringify );
    my $prev_base_dir =
      dir(  $self->url 
          . "/data/"
          . $self->metadata->prev_rdiff . '/'
          . $file_name->dir->stringify );
    $prev_base_dir->mkpath;

# Build absolute path of file in repository and move it from current rdiff to previous rdiff
    unless (
        move(
            "$base_dir/" . $file_name->basename,
            "$prev_base_dir/" . $file_name->basename
        )
      )
    {
        Rdiffopke::Exception::Repository->throw(
            error => "Can not move files within the repository:\n$!" );
    }

# Prune the current rdiff directories if the moved file was the last file of them
    for ( ; rmdir $base_dir ; $base_dir = $base_dir->parent ) {};
};

# See the Rdiffopke::Repository::... description in base class
override '_transfer_file' => sub {
    my $self = shift;
    my $sfile =
      shift;    # Should be a Rdiffopke::File representing the source file

    unless ( $sfile->is_file ) {
        Rdiffopke::Exception::Repository->throw( error =>
"Can not transfer other file types than 'file' to the repository:\n"
        );
    }

    # First we recreate the original arborescence
    my $rfile_name = file( $sfile->rel_path );
    my $base_dir =
      dir(  $self->url 
          . "/data/"
          . $self->metadata->rdiff . '/'
          . $rfile_name->dir->stringify );
    $base_dir->mkpath;

    # $rfile will be the repository file written
    my $rfile = FileHandle->new( ">$base_dir/" . $rfile_name->basename );
    unless ( defined $rfile ) {
        Rdiffopke::Exception::Repository->throw(
            error => "Can not create file in repository\n" );
    }

# Why don't we use File::Copy ? Because source file can come fron anywhere, not only local filesystem
    $sfile->open_r;
    my $buffer;
    while ( $sfile->read($buffer) ) {
        unless ( print $rfile $buffer ) {
            Rdiffopke::Exception::Repository->throw(
                    error => "Error while writing to file '"
                  . "$base_dir/"
                  . $rfile_name->basename
                  . "' in repository\n" );
        }

    }
    $sfile->close;
    $rfile->close;
};

no Moose;
__PACKAGE__->meta->make_immutable;

1;
