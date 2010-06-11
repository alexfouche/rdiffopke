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

has 'path' =>(isa=>'Str', is=>'ro', required=>1);
has 'mode' =>(is=>'ro', isa=>'Any' );
has 'uid' =>(is=>'ro', isa=>'Any' );
has 'gid' =>(is=>'ro', isa=>'Any' );
has 'size' =>(is=>'ro', isa=>'Int' );
has 'mtime' =>(is=>'ro', isa=>'Int' );
has 'type' =>(is=>'ro', isa=>'Rdiffopke::FileType', writer=>'_set_type' );
has 'processed' =>(is=>'ro', isa=>'Bool', writer=>'mark_as_processed' );
has 'verbose' => (is=>'rw', isa =>'Int', default=>0);

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





