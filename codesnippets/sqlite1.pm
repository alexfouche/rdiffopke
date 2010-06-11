

use DBI;
use Data::Dumper;

 my $dbh = DBI->connect( "dbi:SQLite:dbname=/Users/alex/tmp/essai.sqlite3", "", "" );

    $dbh->{RaiseError} = 1;
    $dbh->{PrintError} = 0;
#    $dbh->do("PRAGMA foreign_keys = ON");
#    $dbh->do("PRAGMA default_synchronous = OFF");


$dbh->begin_work;

$dbh->do( 'create table options (name text primary key not null, value text);',);
$dbh->do( 'insert into options values("metadata_version", 1);');

$dbh->do( 
  "update options set value = 4 where name = 'metadata_version';");

$dbh->commit;


my @a=$dbh->selectrow_array('select value from options where name = "metadata_version";');

print (Dumper $a);