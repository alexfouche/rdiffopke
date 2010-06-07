use Data::Dumper;

sub nested {
    Rdiffopke::Exception::Nested->throw( error => 'I feel funny.' );
    die "aarrrghh in nested\n";
}

eval {    #die  "aarrrghh in main";
    nested;
};

if ( my $e = Exception::Class->caught() ) {

    # cleanup();
    print "I got exception $e\n";
}

print "I did my work\n";

BEGIN {

    package Rdiffopke::Exceptions;

    use Exception::Class (
        Rdiffopke::Exception =>
          { description => 'generic Rdiffopke exception' },

        Rdiffopke::Exception::Nested => {
            description => 'nested exception',
            isa         => 'Rdiffopke::Exception',
            alias       => 'nestederror',
        },

        Foo::Bar::Exception::Mainthing => {
            isa         => 'Rdiffopke::Exception',
            description => 'mainthing exception',
        },

    );

    1;
}

__DATA__

