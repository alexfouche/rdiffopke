###############################
#
# Class:  Rdiffopke::File
#
###############################

package Rdiffopke::File;

use Moose;
use FileHandle;
use Moose::Util::TypeConstraints;

subtype 'FileType'
     => as 'Str'
     => where { $_ =~ 'file' || $_ =~ 'dir' || $_ =~ 'slink' }
     => message { "FileType is either 'file', 'dir' or 'slink'" };

has 'path' =>(isa=>'Str', is=>'ro', required=>1);
has 'mode' =>(is=>'ro', isa=>'Any' );
has 'uid' =>(is=>'ro', isa=>'Any' );
has 'gid' =>(is=>'ro', isa=>'Any' );
has 'size' =>(is=>'ro', isa=>'Int' );
has 'mtime' =>(is=>'ro', isa=>'Int' );
has 'type' =>(is=>'ro', isa=>'FileType', writer=>'_set_type' );
has 'processed' =>(is=>'ro', isa=>'Bool', writer=>'mark_as_processed' );

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
$DB::single=1;
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





