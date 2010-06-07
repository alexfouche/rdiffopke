use Data::Dumper;
use Try::Tiny;
use FileHandle;

my $forbidden_file = '/Users/administrator/TOREMOVE'; # We can not write there



sub nested {
	Rdiffopke::Exception::Nested->throw( error => 'I feel funny.' );
	 die "aarrrghh in nested\n";
}

eval  { my $f = FileHandle->new($forbidden_file, 'w');   # I though it would croak or die
print $f "rien";   # Anyway, this one will will croak for sure
 nested; }; 

if ( my $e = Exception::Class->caught() ) {
    # cleanup();
     print "I got exception $e\n";
 }

print "second part\n";


# try { my $f = FileHandle->new($forbidden_file, 'w');   # I though it would croak or die
# print $f "rien";   # Anyway, this one will will croak for sure
# nested; } 
# catch { Rdiffopke::Exception::Mainthing->throw( error => 'Created exception with Try::Tiny' ,show_trace=>1 );
# 	 print "I got exception $_\n";
# };
# my $e;
# if ( $e = Exception::Class->caught()     ) {
#	   print "I consume exception after the TryTIny catch $e\n";
# }


print "\nthird part\n";


# eval { my $f = FileHandle->new($forbidden_file, 'w');   # I though it would croak or die
# print $f "rien";   # Anyway, this one will will croak for sure
#  nested; } ;
# if ( $e = Exception::Class->caught()     ) {
#  $e->isa('Rdiffopke::Exception') or $e=Rdiffopke::Exception::Mainthing->new( error=>$e,show_trace=>1  );
# $e->rethrow;
# }


print "\nfourth part\n";



try {  nested; }
catch { print "I got exception $_\n"; 
		print "exception description is " . $_->description ."\n";
};




print "I did my work\n";

 
 


BEGIN {
package Rdiffopke::Exceptions;

 use Exception::Class (
	Rdiffopke::Exception =>
         { description => 'generic Rdiffopke exception' ,
	# 	isa => 'Exception::Class',
		},
	
     Rdiffopke::Exception::Nested =>
         { description => 'nested exception',
		   isa         => 'Rdiffopke::Exception',
		alias => 'nestederror',
 },

     Rdiffopke::Exception::Mainthing => {
		   isa         => 'Rdiffopke::Exception',
         description => 'mainthing exception',
     },

  );

1;
}

__DATA__

