###############################
#
# Class:  Rdiffopke
#
###############################

package Rdiffopke;

use Moose;
#use Rdiffopke::Repository;
use Rdiffopke::Filesource;


has 'no_encryption' => ( is => 'rw', isa => 'Bool', default => 0 );
has 'verbose'       => ( is => 'rw', isa => 'Bool', default => 0 );
has 'source'     => ( is => 'rw', isa => 'Rdiffopke::Filesource', writer => \&_create_source );
has 'source_url' => ( is => 'rw', isa => 'Str' );
has 'repo_url'   => ( is => 'rw', isa => 'Str' );
#has 'repository' => ( is => 'rw', isa => 'Rdiffopke::Repository', );
has 'version'    => ( is => 'ro', isa => 'Num', default => 0.1 );
has 'need_metadata_schema_version' =>
  ( is => 'ro', isa => 'Int', default => 1 );


sub _create_source {
	
	
}

sub terminate {
}

no Moose;
__PACKAGE__->meta->make_immutable;
