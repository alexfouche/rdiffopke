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
use Try::Tiny;

extends 'Rdiffopke::Repository';

has '_userkey_file'    => ( is => 'ro', isa => 'Str', writer => '_set_userkey_file' );
has '_metadata_dbfile' => ( is => 'ro', isa => 'Str', writer => '_set_metadata_dbfile' );

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

    ::verbose_message( "Checking and initializing rdiff repository '" . $self->url . "'" )
        if ($Rdiffopke::verbose);

    if ( -e $self->url && !-d $self->url ) {
        Rdiffopke::Exception::Repository->throw( error => "The local rdiff repository '"
                . $self->url
                . "' already exists and is not a directory\n" );
    } else {
        mkdir $self->url;
    }

    unless ( -d $self->url
        && -x $self->url
        && -w $self->url )
    {
        Rdiffopke::Exception::Repository->throw(
            error => "Directory '" . $self->url . "' is neither writable nor browseable\n" );
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

    Rdiffopke::Exception::Repository->throw( error => "TODO __PACKAGE__ __LINE__\n" );

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

    dir( $self->url, 'data' )->mkpath;

    # Create a symlink for convenience if users want to browse the repository. Some platforms do not support symlinks
    try {
        unlink( file( $self->url, 'latest_rdiff' )->stringify );
        unlink( file( $self->url, 'data', '_latest_rdiff' )->stringify );
        symlink(
            file( 'data',     $self->metadata->rdiff )->stringify,
            file( $self->url, 'latest_rdiff' )->stringify
        );
        symlink( $self->metadata->rdiff, file( $self->url, 'data', '_latest_rdiff' )->stringify );
    };

    # nothing to do if the previous rdiff is 0 (the repository is new)
    return if ( $self->metadata->prev_rdiff == 0 );

    my $prev_rdiff_dir = dir( $self->url, 'data', $self->metadata->prev_rdiff )->stringify;
    my $rdiff_dir      = dir( $self->url, 'data', $self->metadata->rdiff )->stringify;

# Fail if there is already a directory named after the current(new) rdiff number
    if ( -d $rdiff_dir ) {
        Rdiffopke::Exception::Repository->throw(
            error => "Directory '$rdiff_dir' should not already exist in the repository\n" );
    }

    # Fail if the previous rdiff directory is missing
#    unless ( -d $prev_rdiff_dir ) {
#        Rdiffopke::Exception::Repository->throw( error => "Previous rdiff directory '$prev_rdiff_dir' is missing from the repository\n" );
#    }
#
# In fact there are cases when the previous rdiff_dir can be missing if the source directory was empty(ed)

    if ( -d $prev_rdiff_dir ) {
        unless ( rename $prev_rdiff_dir, $rdiff_dir ) {
            Rdiffopke::Exception::Repository->throw( error =>
                    "Can not rename '$rdiff_dir' should not already exist in the repository\n" );
        }
    }
# else {
#	 unless ( mkdir $rdiff_dir ) {
#	        Rdiffopke::Exception::Repository->throw( error =>
#	"Can not create '$rdiff_dir'\n"
#	        );
#	    }
#}
};

# See the Rdiffopke::Repository::... description in base class
override '_discard_file' => sub {
    my $self = shift;
    my $file = shift;    # Should be a Rdiffopke::File

    # Commented because :
    # There is a case when a file on the source has been replaced by something which is not a "file" (eg a folder), and has same path+name
    # Nevertheless, the current function is given the source file in $sfile, which in this specific case is not of type 'file'
    # So having the check below would prevent the file in repository from the previous rdiffopke run to be moved to previous rdiff
    # So instead, we will do a real check if the file exists in repo and move it if it exists
    # unless ( $file->is_file ) {
    #     Rdiffopke::Exception::Repository->throw( error =>"Can not discard other file types than 'file' from the repository:\n" );
    # }

    my $file_name = file( $self->url, 'data', $self->metadata->rdiff, $file->rel_path )
        ;                # Use ',' construction to make it portable

    # Maybe the file does not exists if it is new
    if ( !-e $file_name ) { return; }

    # First we recreate the original arborescence in the previous rdiff dir
    my $base_dir = $file_name->dir;
    my $prev_base_dir =
        dir( $self->url, 'data', $self->metadata->prev_rdiff, file( $file->rel_path )->dir )
        ;                # Use ',' construction to make it portable
    $prev_base_dir->mkpath;


# Build absolute path of file in repository and move it from current rdiff to previous rdiff
    unless (
        move(
            file( "$base_dir",      $file_name->basename )->stringify,
            file( "$prev_base_dir", $file_name->basename )->stringify
        )
        )
    {
        Rdiffopke::Exception::Repository->throw(
            error => "Can not move files within the repository:\n$!" );
    }

# Prune the current rdiff directories if the moved file was the last file of them
    for ( ; rmdir $base_dir ; $base_dir = $base_dir->parent ) { }
};

# See the Rdiffopke::Repository::... description in base class
override '_transfer_file' => sub {
    my $self  = shift;
    my $sfile = shift;    # Should be a Rdiffopke::File representing the source file

    unless ( $sfile->is_file ) {
        Rdiffopke::Exception::Repository->throw(
            error => "Can not transfer other file types than 'file' to the repository:\n" );
    }

    # First we recreate the original arborescence
    my $rfile_rel_path = $sfile->rel_path;
    my $rfile = file( $self->url, 'data', $self->metadata->rdiff, $sfile->rel_path )
        ;                 # Use ',' construction to make it portable
    my $base_dir = $rfile->dir;
    $base_dir->mkpath;

    # From now, $sfile is Rdiffopke::File, $rfile is Path::Class::File, and $rfile_h is FileHandle

    # $rfile_h will be the repository file written
    my $rfile_h = FileHandle->new( '>' . file( $base_dir, $rfile->basename )->stringify );
    unless ( defined $rfile_h ) {
        Rdiffopke::Exception::Repository->throw( error => "Can not create file in repository\n" );
    }

# Why don't we use File::Copy ? Because source file can come from anywhere, not only local filesystem, this is the reason the Rdiffopke::File virtual object exists
    $sfile->open_r;
    my $buffer;
    while ( $sfile->read($buffer) ) {
        unless ( print $rfile_h $buffer ) {
            Rdiffopke::Exception::Repository->throw( error => "Error while writing to file '"
                    . file( $base_dir, $rfile->basename )->stringify
                    . "' in repository\n" );
        }

    }
    $sfile->close;
    $rfile_h->close;

    my $stat = $rfile->stat;
    # returns a small array [localpath, 'mtime', 'size'] of the file stored in the repository
    return [ $rfile_rel_path, $stat->mtime, $stat->size ];
};

# Verify parts that are relevant to specific implementation of repository
override '_verify' => sub {
    my $self = shift;

};

no Moose;
__PACKAGE__->meta->make_immutable;

1;
