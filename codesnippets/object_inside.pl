#!/opt/local/bin/perl

use strict;
print "i begin here\n";
my $a = Critter->new;
$a->display;
my $b = Cafard::de::lespace->new;
$b->display;

print "i end here\n";
exit 0;


# Just check if we can declare objects in the same file but at the end

package Critter;
sub new { return bless {}; }
sub display {
    my $self  = shift;
    print "i am a " . ref($self) . ", whatever this word means\n";
}


package Cafard::de::lespace;
sub new { return bless {}; }
sub display {
    my $self  = shift;
    print "i am a " . ref($self) . "\n";
}


