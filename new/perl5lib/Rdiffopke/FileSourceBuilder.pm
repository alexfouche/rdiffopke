###############################
#
# Class:  Rdiffopke::FileSourceBuilder
#
###############################

package Rdiffopke::FileSourceBuilder;

use Moose;
use Rdiffopke::FileSource::_LocalDir;
use Rdiffopke::Exception;

has 'url'       => ( is => 'ro', isa => 'Str', required=>1 );

sub instance {
my $self = shift;

$DB::single=1;

$_=$self->url;
	SWITCH:  {
	    /^file:\/\// && do { $self->url( $self->url =~ s-^file://--); last SWITCH; };
	    /^sftp:\/\// && do {  last SWITCH; };
	    /^ftp:\/\// && do { last SWITCH; };
	}

	# If we did not returned yet, maybe it is a local directory
  if ( -d $self->url) { return Rdiffopke::FileSource::_LocalDir->new(url=>$self->url) ;}
	
# We should never get there
	Rdiffopke::Exception::FileSource->throw(error=>"Source URL is not recognized");
}

no Moose;
__PACKAGE__->meta->make_immutable;
