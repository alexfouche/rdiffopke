# Note, this object is supposed to do nothing more than to host an array. Use List::Object instead


###############################
#
# Class:  Rdiffopke::Filelist
#
###############################

package Rdiffopke::Filelist;

use Moose;
use Rdiffopke::File;

has 'list' => (
    is      => 'ro',
    isa     => 'ArrayRef[Rdiffopke::File]',
    default => sub { [] }
  );
has '_iterator' => (is=>'rw', isa=>'Int', default=>0 );

sub add {
    my ( $self, $item ) = @_;

$DB::single=1;
#    if ( defined($item) && $item->isa('Rdiffopke::File') ) {
#        $self->list->{ $item->path } = $item;
#    }
push @{$self->{list}}, $item  if ( defined($item)&& $item->isa('Rdiffopke::File')); 
}



no Moose;
__PACKAGE__->meta->make_immutable;

1;
