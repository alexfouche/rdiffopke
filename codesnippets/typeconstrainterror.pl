package Something::File;
use Moose;
use namespace::autoclean;

has 'type' =>(is=>'ro', isa=>'Str', writer=>'_set_type' );

sub is_slink {
	my $self = shift;
	return ( $self->type eq 'slink' );
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;


package Something::File::LocalFile;
use Moose;
use Moose::Util::TypeConstraints;


extends 'Something::File';

subtype 'PositiveInt'
 	 =>	as 'Int'
     => where { $_ >0 }
     => message { 'Only positive greater than zero integers accepted' };

no Moose;
__PACKAGE__->meta->make_immutable;
1;


my $a = Something::File::LocalFile->new;
$a->_set_type('slink');
print $a->is_slink ." end\n"; 

