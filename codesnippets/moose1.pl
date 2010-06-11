use Data::Dumper;

#!/opt/local/bin/perl

package Animal;

sub new{ return bless {whatami=>"idunno", tellsomething=>"something"}};

sub ouah{
	die "What i am i supposed to do ?\n";
}

1;

package Animal::Dog;
use Moose;

extends Animal;

has '+whatami' => ( is=>'ro', isa=> 'Str', default=>'dog');


sub ouah{
	print "ouah !\n";
}


no moose;
__PACKAGE__->meta->make_immutable();

package main;

my $a = Animal::Dog->new;
$a->ouah;
print (Dumper $a);

exit 0;


