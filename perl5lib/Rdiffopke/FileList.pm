###############################
#
# Class:  Rdiffopke::Filelist
#
###############################

package Rdiffopke::Filelist;

use base qw(List::Object); # Yes, that is all, just a redefinition

sub new {
	return bless List::Object->new(type=>'Rdiffopke::File');
}

1;
