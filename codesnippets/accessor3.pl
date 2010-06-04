#!/opt/local/bin/perl


package Critter;
use Mouse;
has 'color' => (is => 'rw', isa => 'Str');

sub new{ return bless {color=>'green'}};

sub display {
    my $self = shift;
    print "i am a " .$self->color .' '  . ref($self) . ", whatever this word means\n";
}

__PACKAGE__->meta->make_immutable();

package main;

my $a = Critter->new;
$a->color("blue");
$a->display;
exit 0;

