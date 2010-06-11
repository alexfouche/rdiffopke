###############################
#
# Class:  Rdiffopke::FileSource::_Localdir
#
###############################

package Rdiffopke::FileSource::_LocalDir;

use Moose;
use Rdiffopke::FileList;
use Path::Class::Dir;
use Rdiffopke::File::_LocalFile;
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

    my $file_list = Rdiffopke::Filelist->new;
    my $dir       = Path::Class::Dir->new( $self->url )->cleanup->absolute;

## Path::Class::Dir->recurse() follows symlinks !!! ->use File::Find instead
    #    $dir->recurse(
    #        callback => sub {
    find(
        sub {
            my $stat = stat($_);
            $file_list->add(
                Rdiffopke::File::_LocalFile->new(
                    path => $File::Find::name,
                    mode => $stat->mode,
                    uid  => $stat->uid,
                    gid  => $stat->gid,
                    size => $stat->size,

                    # mtime => scalar( gmtime( $stat->mtime ) ),
                    mtime => $stat->mtime,
                )
            );
        },
        $dir->stringify,
    );

    return $file_list;
};

no Moose;
__PACKAGE__->meta->make_immutable;

1;
