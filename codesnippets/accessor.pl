    #!/opt/local/bin/perl

    # The whole Class::Accessor thing does not work !!

    my $a = Critter->new;
    $a->color("blue");
    $a->display;
    exit 0;

    package Critter;
        use base qw(Class::Accessor );
        Critter->mk_accessors ("color" );

        sub display {
            my $self  = shift;
            print "i am a $self->color " . ref($self) . ", whatever this word means\n";
        }
