
###############################
#
    # Class:  Rdiffopke::Userkey
    #
###############################

package Rdiffopke::Userkey;
use Moose;

has '_dir' =>  ( is => 'wo', isa => 'Str', required=>1, trigger   => \&_set_filename );
has '_filename' => ( is => 'ro', isa => 'Str',  builder=>'_set_filename');
has '_verbose' => ( is => 'ro', isa => 'Bool', default => 0 );

   
    sub exists {
        my $self = shift;
        ( -e $self->_filename ) ? 1 : 0;
    }

sub _set_filename {
	my $self = shift;
  return $self->_dir . '/pubkey';
}

	no Moose;
	__PACKAGE__->meta->make_immutable;
