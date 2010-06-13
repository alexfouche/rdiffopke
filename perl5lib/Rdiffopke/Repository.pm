###############################
#
# Class:  Rdiffopke::Repository
#
###############################

package Rdiffopke::Repository;

use Moose;
use Rdiffopke::Metadata;
use Rdiffopke::UserKey;
use Rdiffopke::Exception;
use Rdiffopke::SubTypes;

has 'no_encryption' => ( is => 'ro', isa => 'Bool', default  => 0 );
has 'url'           => ( is => 'ro', isa => 'Str',  required => 1 );
has 'need_metadata_schema_version' =>
  ( is => 'ro', isa => 'Int', required => 1 );

#has 'need_metadata_schema_version' =>( is => 'ro', isa => 'PositiveInt', required => 1 ); # TOFIX why is TypeConstraint not working ?
has 'metadata' =>
  ( is => 'ro', isa => 'Rdiffopke::Metadata', writer => '_set_metadata' );
has 'userkey' =>
  ( is => 'ro', isa => 'Rdiffopke::UserKey', writer => '_set_userkey' );
has 'list_files_to_discard_from_repo' => (
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub { [] },
    writer  => '_set_list_files_to_discard_from_repo'
);
has 'list_files_to_transfer' => (
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub { [] },
    writer  => '_set_list_files_to_transfer'
);
has 'list_files_to_update_metadata' => (
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub { [] },
    writer  => '_set_list_files_to_update_metadata'
);
has 'source_url' => ( is => 'ro', isa => 'Str', required => 1 )
  ;    # For informational purposes only

sub BUILD {
    my $self = shift;

    if ( ref($self) eq 'Rdiffopke::Repository' ) {
        Rdiffopke::Exception::Repository->throw( error =>
"The Rdiffopke::Repository class is a base virtual class and can not be instanciated\n"
        );
    }
}

# The prepare() of the base class contains checks and create metadata and userkey instances.
# Create a 'before prepare' function in the child class instead of overriding this function,
# and open or create your repository and apply checks depending on the medium/architecture/organisation
# of your repository
sub prepare {
    my $self = shift;

    if ( !$self->userkey_exists && !$self->no_encryption && $self->has_data ) {
        Rdiffopke::Exception::Repository->throw( error =>
"Repository has data inside but is missing the public key file and you requested encryption\n"
        );
    }

    if ( $self->no_encryption && $self->userkey_exists ) {
        Rdiffopke::Exception::Repository->throw( error =>
"You have requested no encryption but there is a public key file\n"
        );
    }

    if (   !$self->no_encryption
        && !$self->userkey_exists
        && $self->metadata->exists )
    {
        Rdiffopke::Exception::Repository->throw( error =>
"There is a metadata file  but the public key file is missing ! Set to 'no encryption' if you never used it there\n"
        );
    }

    $self->_set_metadata(
        Rdiffopke::Metadata->new(
            dbfile     => $self->_get_metadata_dbfile,
            upgrade_to => $self->need_metadata_schema_version,
                   )
    );
    $self->_set_userkey(
        Rdiffopke::UserKey->new(
            key     => $self->_create_get_userkey,
                    )
    ) unless ( $self->no_encryption );

    ::verbose_message(
        "Finished preparing repository at '" . $self->url . "'\n" )
      if ( $Rdiffopke::verbose );
}

sub _get_metadata_dbfile {
    my $self = shift;

    if ( ref($self) eq 'Rdiffopke::Repository' ) {
        Rdiffopke::Exception::Repository->throw( error =>
              "The _get_metadata_dbfile function needs to be overriden\n" );
    }
}

sub _create_get_userkey {
    my $self = shift;

    if ( ref($self) eq 'Rdiffopke::Repository' ) {
        Rdiffopke::Exception::Repository->throw( error =>
              "The '_create_get_userkey' function needs to be overriden\n" );
    }
}

sub set_message {
    my ( $self, $message ) = @_;
    $self->metadata->set_message($message) if ( defined $self->metadata );
}

sub metadata_exists {
    my $self = shift;

    if ( ref($self) eq 'Rdiffopke::Repository' ) {
        Rdiffopke::Exception::Repository->throw(
            error => "The 'userkey_exists' function needs to be overriden\n" );
    }
}

sub userkey_exists {
    my $self = shift;

    if ( ref($self) eq 'Rdiffopke::Repository' ) {
        Rdiffopke::Exception::Repository->throw(
            error => "The 'userkey_exists' function needs to be overriden\n" );
    }
}

sub close {
    my $self = shift;
    $self->metadata->close if ( defined $self->metadata );

    # userkey was already saved at creation time;

# Do an 'after close' in your Repository::_ChildClass, to push back the metadata db file if your Repo is remote
}

sub schema_version {
    my $self = shift;
    return $self->metadata->schema_version if ( defined $self->metadata );
}

sub DEMOLISH {
    $_[0]->close;
}

# Will generate 3 arrays of Rdiffopke::File refs
sub compare_files {
    my $self             = shift;
    my $source_file_list = shift;

    unless ( defined($source_file_list)
        && $source_file_list->isa('Rdiffopke::FileList') )
    {
        Rdiffopke::Exception::Repository->throw( error =>
"Function 'compare_files' needs to be given a FileList instance of the files on the source\n"
        );
    }

# I suppose if lists are big, it is better to use directly variables instead of accessors

    my $repo_file_list = $self->metadata->get_detailed_file_list;

    my @list_files_to_transfer          = ();
    my @list_files_to_update_metadata   = ();
    my @list_files_to_discard_from_repo = ();

    foreach ( keys %$source_file_list ) {
        if ( $repo_file_list->{$_} ) {

            # It exists in repository, so check if metadata is modified
            # mode, uid, gid, size, mtime, type,
            if (
                $source_file_list->{$_}->mtime ne $repo_file_list->{$_}->mtime
                || $source_file_list->{$_}->size != $repo_file_list->{$_}->size
                || (
                    $source_file_list->{$_}->type ne $repo_file_list->{$_}->type
                    && $source_file_list->{$_}->type ne 'dir' )
              )
            {
                push( @list_files_to_transfer, $source_file_list->{$_} );
                next;
            }
            push( @list_files_to_update_metadata, $source_file_list->{$_} )
              if ( $source_file_list->{$_}->mode ne $repo_file_list->{$_}->mode
                || $source_file_list->{$_}->uid  ne $repo_file_list->{$_}->uid
                || $source_file_list->{$_}->gid  ne $repo_file_list->{$_}->gid
                || $source_file_list->{$_}->type ne
                $repo_file_list->{$_}->type );
            $repo_file_list->{$_}->{processed} = 1;
        }
        else {

            # Needs transfer
            push @list_files_to_transfer, $source_file_list->{$_};
        }
    }
    push( @list_files_to_discard_from_repo, $repo_file_list->{$_} ) foreach (
        grep { !$repo_file_list->{$_}->{processed} }
        keys(%$repo_file_list)
    );

    $self->_set_list_files_to_discard_from_repo(
        \@list_files_to_discard_from_repo );
    $self->_set_list_files_to_update_metadata(
        \@list_files_to_update_metadata );
    $self->_set_list_files_to_transfer( \@list_files_to_transfer );
}

# Move all the files (not the metadata) from previous rdiff to a new rdiff folder
# This means renaming the folder named with the previous rdiff number to a new folder named with the current(new) rdiff number,
# and create an empty folder named with the previous rdiff number.
# This previous rdiff folder will be later in other function populated to keep increments of files if files are either discarded
# or modified against source.
sub _move_files_to_last_rdiff {
    my $self = shift;

    if ( ref($self) eq 'Rdiffopke::Repository' ) {
        Rdiffopke::Exception::Repository->throw( error =>
              "The 'move_files_to_last_rdiff' function needs to be overriden\n"
        );
    }
}

sub transfer_files {
    my $self = shift;

    # Simple check we did not mess with the instance before beginning transfer
    unless ( defined( $self->list_files_to_transfer )
        && defined( $self->list_files_to_discard_from_repo )
        && defined( $self->list_files_to_update_metadata ) )
    {
        Rdiffopke::Exception::Repository->throw( error =>
"Some of the transfer plans are not defined. Was a 'compare_files()' run ?\n"
        );
    }

# We add the new rdiff, and move all the files from the previous rdiff to the new rdiff (since they are by default considered not to have been modified)
    $self->metadata->add_rdiff;
    $self->metadata->elevate_files_to_last_rdiff
      ;    # Will put all files that are rdiff-1 to rdiff in metadata only
    $self->_move_files_to_last_rdiff
      ;    # Will move all files from directory rdiff-1 to rdiff

    $self->metadata->set_message(
        'Moved all files from previous rdiff to new rdiff');

# Below, i manage both the repository part and the metadata part, instead of letting the relevant repository function
# update itself the relevant metadata.
# This is because the metadata functions methods (eg metadata->discard_file) are generic, while the repository methods ($self->_discard_file)
# are methods of a child repository class that need to be overwritten to bespecific to the repository actual storage.
# So you do not have to manage the metadata method calls in your child repository class.

# TOFIX: I think there might be a bug if a file type changes on the source (eg from file to slink or dir), then it will not be discarded in repository. Also, if a file was a dir or slink and changes to file ?

# Transfer all new or modified files from source.
# This will push current file and metadata to previous rdiff, and transfer source file and metadata to new rdiff
# This means a discard of current file in repository to previous rdiff, and add source file to new rdiff
# $_ is a Rdiffopke::File instance
    foreach ( @{ $self->list_files_to_transfer } ) {
        $self->metadata->discard_file($_)
          ;    # push modified metadata and file content to previous rdiff
        $self->_discard_file($_)
          if ( $_->is_file );    # push repository file to previous rdiff folder

# $localfile is a small array [localpath, 'mtime', 'size'] of the file stored in the repository
        my $localfile = $self->_transfer_file($_)
          if ( $_->is_file )
          ; # Transfer the file from source to repository in new rdiff directory
        $self->metadata->add_file( $_, $localfile )
          ; # recreate update metadata and associate reference to file in repository
    }
    $self->_set_list_files_to_transfer( [] );    # can't hurt

# Update metadata of files that changed, but whose content (based on size and mtime) was not modified
# This will push current file metadata to to previous rdiff, and add new metadata to new rdiff.
# This will not transfer file content from source to repository. Content is believed to be the same as the one already stored in repo
# $_ is a Rdiffopke::File instance
    foreach ( @{ $self->list_files_to_update_metadata } ) {
        $self->metadata->replace_file_metadata($_)
          ; # push modified metadata to previous rdiff and replace with a new one
    }
    $self->_set_list_files_to_update_metadata( [] );    # can't hurt

    # Discards files that have disappeared from source
    # This means pushing both metadata and real file to previous rdiff
    # $_ is a Rdiffopke::File instance
    foreach ( @{ $self->list_files_to_discard_from_repo } ) {
        $self->metadata->discard_file($_)
          ;    # push modified metadata to previous rdiff
        $self->_discard_file($_)
          if ( $_->is_file );    # push repository file to previous rdiff folder
    }
    $self->_set_list_files_to_discard_from_repo( [] );    # can't hurt

    $self->metadata->set_message( 'Repository synced with source '
          . $self->source_url
          . ' successfully' );
}

# push repository file to previous rdiff folder
sub _discard_file {
    my $self     = shift;
    my $rel_path = shift;

    if ( ref($self) eq 'Rdiffopke::Repository' ) {
        Rdiffopke::Exception::Repository->throw(
            error => "The '_discard_files' function needs to be overriden\n" );
    }
}

# Transfer the file from source to repository in new rdiff directory
# returns a small array [localpath, 'mtime', 'size'] of the file stored in the repository
sub _transfer_file {
    my $self = shift;
    my $file = shift;

    if ( ref($self) eq 'Rdiffopke::Repository' ) {
        Rdiffopke::Exception::Repository->throw(
            error => "The '_add_file' function needs to be overriden\n" );
    }

# returns a small array [localpath, 'mtime', 'size'] of the file stored in the repository
# return [localpath, mtime, size]
}

sub verify {
    my $self = shift;

    $self->prepare unless ( defined $self->metadata );

	# Here verify parts generic for all repository implementations
	
	# Here verify parts that are only relevant to metadata alone 
	$self->metadata->verify;
	
	# Here verify parts that are relevant to specific implementation of repository
    $self->_verify;


	# TODO
	# check if there are empty dirs in repo (all data/xx/ dirs)
	# foreach rdiff
    #		get detailled list  of files in repo, with size and date
	#		compare with metadata 
	#       check if metadata contains files which should be in repo
	
	# Metadata 
	# check if metadata has doublons in localfiles, files or paths table
	# check integrity of db with rdiff, check if there are orphans


}

sub _verify {
    my $self = shift;

    if ( ref($self) eq 'Rdiffopke::Repository' ) {
        Rdiffopke::Exception::Repository->throw(
            error => "The '_verify' function needs to be overriden\n" );
    }
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
