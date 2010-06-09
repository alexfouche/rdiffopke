###############################
#
# Class:  Rdiffopke
#
###############################

package Rdiffopke;

use Moose;
#use Rdiffopke::Repository;
use Rdiffopke::FileSourceBuilder;
use Rdiffopke::FileSource;



has 'no_encryption' => ( is => 'rw', isa => 'Bool', default => 0 );
has 'verbose'       => ( is => 'rw', isa => 'Bool', default => 0 );
has 'source'     => ( is => 'ro', isa => 'Rdiffopke::FileSource', writer=>'_set_source'  );
has 'source_url' => ( is => 'rw', isa => 'Str' , trigger => \&_create_source);
has 'repo_url'   => ( is => 'rw', isa => 'Str' );
#has 'repository' => ( is => 'rw', isa => 'Rdiffopke::Repository', );
has 'version'    => ( is => 'ro', isa => 'Num', default => 0.1 );
has 'need_metadata_schema_version' =>
  ( is => 'ro', isa => 'Int', default => 1 );


sub _create_source {
	my $self=shift;
$DB::single = 1;
	$self->_set_source( Rdiffopke::FileSourceBuilder->new(url=>$self->source_url)->instance);
}

sub prepare_source {
	my $self=shift;
#	$self->source->prepare;
} 

sub terminate {
	
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;