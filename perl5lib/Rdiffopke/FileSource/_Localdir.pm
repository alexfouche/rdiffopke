###############################
#
# Class:  Rdiffopke::FileSource::_LocalDir
#
###############################

package Rdiffopke::FileSource::_LocalDir;

use Moose;
use Rdiffopke::FileList;
use Path::Class;
use Rdiffopke::File::_LocalFile;
use Rdiffopke::Exception;
use File::Find;
use File::stat;

extends 'Rdiffopke::FileSource';

# because "after 'new'" does not work
sub BUILD {
    my $self = shift;

    unless ( -d $self->url ) {
        Rdiffopke::Exception::FileSource->throw(
            error => "Local directory " . $self->url . " does not exists" );
    }
}

override 'get_detailed_file_list' => sub {
    my $self = shift;

    my $file_list = Rdiffopke::FileList->new;
    my $dir       = dir( $self->url )->cleanup->absolute;
    # my $root_path = $dir->stringify;

## Path::Class::Dir->recurse() follows symlinks !!! ->use File::Find instead
    #    $dir->recurse(
    #        callback => sub {
    find(
        {
            wanted => sub {
                my $stat     = lstat($_);
                my $rel_path = file($File::Find::name)->relative($dir);
                # my $rel_path = $File::Find::name;
                # $rel_path =~ s/^$root_path\/// ;   # Not portable

                my $finded_file = Rdiffopke::File::_LocalFile->new(
                    rel_path => $rel_path->stringify,
                    path     => $File::Find::name,
                    mode     => $stat->mode,
                    uid      => $stat->uid,
                    gid      => $stat->gid,
                    size     => $stat->size,
                    # mtime => scalar( gmtime( $stat->mtime ) ),
                    mtime => $stat->mtime,
                );

                # Sanitize symlink if needed
                if ( defined( $finded_file->target ) ) {
                    my $tmpfile = file( $finded_file->target )->cleanup;
                    $tmpfile = file( $dir, $tmpfile ) if ( $tmpfile->is_relative );
                    $finded_file->target( $tmpfile->relative($dir)->stringify )
                        if ( $dir->subsumes($tmpfile) );
                }

                $file_list->add( $rel_path, $finded_file );
            },
            no_chdir => 1,
            follow   => 0,
        },
        $dir->stringify,
    );

    # Make sure we do not include the base directory
    $file_list->delete('.');
    $file_list->delete($dir);

    return $file_list;
};

no Moose;
__PACKAGE__->meta->make_immutable;

1;
