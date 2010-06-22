###############################
#
# Class:  Rdiffopke::File
#
###############################

package Rdiffopke::File;

use Moose;
use FileHandle;
use Rdiffopke::SubTypes;
#use namespace::autoclean; # because attribute 'type' and its accessors conflict with method 'type' of Moose::Util::TypeConstraints
use Rdiffopke::SubTypes;
use Rdiffopke::Exception;

has 'path' =>(isa=>'Maybe[Str]', is=>'ro', required=>1); # path is the full path/url to locate the file on the medium, whichever it is source or repository
has 'rel_path' =>(isa=>'Str', is=>'ro', required=>1); # rel_path is the relative path in the source
has 'mode' =>(is=>'ro', isa=>'Any' );
has 'uid' =>(is=>'ro', isa=>'Any' );
has 'gid' =>(is=>'ro', isa=>'Any' );
has 'size' =>(is=>'ro', isa=>'Int' );
has 'mtime' =>(is=>'ro', isa=>'Any' );
has 'type' =>(is=>'ro', isa=>'Str', writer=>'_set_type' ); # TOFIX why is TypeConstraint not working ?
#has 'type' =>(is=>'ro', isa=>'Rdiffopke::FileType', writer=>'_set_type' ); # TOFIX why is TypeConstraint not working ?
has 'processed' =>(is=>'ro', isa=>'Bool', writer=>'mark_as_processed' );
has 'file_id' =>(is=>'ro', isa=>'Any' );


sub BUILD {
	my $self = shift;
	
    if (ref($self) eq 'Rdiffopke::File' ){Rdiffopke::Exception::File->throw( error =>
"The Rdiffopke::File class is a base virtual class and can not be instanciated\n"
    );}
}

sub read {
    Rdiffopke::Exception::FileSource->throw(
        error => "The read() function should be overridden\n" );
}

sub open_r {}

sub close { }

sub is_file {
	my $self = shift;
	return ( $self->type eq 'file' );
}
sub is_dir {
	my $self = shift;
	return ( $self->type eq 'dir' );
}
sub is_slink {
	my $self = shift;
	return ( $self->type eq 'slink' );
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;





