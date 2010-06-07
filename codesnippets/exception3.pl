
#use autodie qw(:all);

use Data::Dumper;
use Try::Tiny;


try {#die  "aarrrghh in main";
try { die "aarrrghh in nested\n";} catch {print "in nested catch: died: $_\n"; die "$_"};;
} catch {print "in catch: died: $_\n"};


