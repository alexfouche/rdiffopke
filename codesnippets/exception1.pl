use Data::Dumper;
use Exception::Class (
      'Rdiffopke::Exception',
      'Rdiffopke::Exception::FileSource' => { isa => 'Rdiffopke::Exception',
		description => 'some text for the FileSource exception' ,
		alias	=> 'filesourceerror',
	}

  );


eval { Rdiffopke::Exception::FileSource->throw( error => 'I feel funny.' ) };

if (my $e = Exception::Class->caught ) {
	print "i received exception " . Dumper($e); };

