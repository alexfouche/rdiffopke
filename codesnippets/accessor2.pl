    #!/opt/local/bin/perl

package main;

    my $a = Critter->new;
    $a->color("blue");
    $a->display;
    exit 0;

    package Critter;
        use Class::Accessor::Classy;

  sub new{ return bless {color=>'green'}};
    rw qw(color);                # read-write

        sub display {
            my $self  = shift;
            print "i am a $self->color " . ref($self) . ", whatever this word means\n";
        }
