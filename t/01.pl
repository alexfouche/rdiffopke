#!/usr/bin/perl

use strict;
use Test::More;
use Rdiffopke;
use File::Temp qw(tempdir);
use FileHandle;
use Path::Class;
use File::Path;

#  BEGIN { use_ok($module); }
#  BEGIN { require_ok($module); }
#  BEGIN { require_ok($file); }
#  ok($got eq $expected, $test_name);
#  is  ( $got, $expected, $test_name );
#  isnt( $got, $expected, $test_name );
#  like( $got, qr/expected/, $test_name );
#  unlike( $got, qr/expected/, $test_name );
#  cmp_ok( $got, $op, $expected, $test_name );
#  can_ok($module, @methods);
#  can_ok($object, @methods);
#  isa_ok($object,   $class, $object_name);
#  isa_ok($subclass, $class, $object_name);
#  isa_ok($ref,      $type,  $ref_name);
#  my $obj = new_ok( $class => \@args );
#  pass($test_name);
#  fail($test_name);
#  is_deeply( $got, $expected, $test_name );
#  diag(@diagnostic_message);
#  note(@diagnostic_message);
#  my @dump = explain @diagnostic_message;
#  SKIP: {
#      skip $why, $how_many if $condition;
#      ...normal testing code goes here...
#    }
#  TODO: {
#      local $TODO = $why if $condition;
#      ...normal testing code goes here...
#      }
#  TODO: {
#      todo_skip $why, $how_many if $condition;
#      ...normal testing code...
#  }
#  BAIL_OUT($reason);

BEGIN {
	use_ok('Rdiffopke');
	use_ok('Rdiffopke::UserKey');
	use_ok('Rdiffopke::Subtypes');
	use_ok('Rdiffopke::RepositoryBuilder');
	use_ok('Rdiffopke::Repository');
	use_ok('Rdiffopke::Repository::_LocalDir');
	use_ok('Rdiffopke::Metadata');
	use_ok('Rdiffopke::FileSourceBuilder');
	use_ok('Rdiffopke::FileSource');
	use_ok('Rdiffopke::FileSource::_LocalDir');
	use_ok('Rdiffopke::FileList');
	use_ok('Rdiffopke::File');
	use_ok('Rdiffopke::File::_LocalFile');
	use_ok('Rdiffopke::Exception');
 }



sub create_file {
	my ($dirname,$filename, $content) = @_;
	die unless (defined $dirname && defined $filename);
	my $file = FileHandle->new('>'. file($dirname, $filename)->stringify);
	print $file $content if (defined $content);
	$file->close;
	return $file;
}

sub metadata_connect {
	my $file = shift;
	return DBI->connect( "dbi:SQLite:dbname=" . $file, "", "" );
}

my $sourcedir=File::Temp->newdir;;

my $repodir=File::Temp->newdir;
rmtree($repodir->dirname);
ok(!-e $repodir->dirname);


my %feed_to_rdiffopke = (verbose=>0, no_encryption=>1, source_url=> $sourcedir->dirname, repo_url=>$repodir->dirname);
my $rdiffopke = Rdiffopke->new(%feed_to_rdiffopke);
isa_ok( $rdiffopke, 'Rdiffopke' );

# Connect to repository or create it if does not exist
# Check repo and metadata, upgrade schema if needed
$rdiffopke->prepare_repository;
ok(-d $repodir->dirname, 'Repository dir was created');
ok(-f file($repodir->dirname,'metadata')->stringify, 'Metadata file was created');
ok(!-f file($repodir->dirname,'pubkey')->stringify, 'Public key file was not created');

my $metadata_dbh=metadata_connect(file($repodir->dirname,'metadata')->stringify);
isa_ok($metadata_dbh, 'DBI::db');
is($metadata_dbh->selectrow_array('select name from options where name="metadata_version";'), 'metadata_version', 'Check if metadata skeleton is created');
is($metadata_dbh->selectrow_array('select count(*) from rdiffs;'), 0, 'Check if metadata rdiff table is empty');
is($metadata_dbh->selectrow_array('select count(*) from files;'), 0, 'Check if metadata files table is empty');
is($metadata_dbh->selectrow_array('select count(*) from paths;'), 0, 'Check if metadata paths table is empty');
is($metadata_dbh->selectrow_array('select count(*) from localfiles;'), 0, 'Check if metadata localfiles table is empty');
is($metadata_dbh->selectrow_array('select count(*) from keys;'), 0, 'Check if metadata keys table is empty');
is($metadata_dbh->selectrow_array('select count(*) from options;'), 1, 'Only 1 option in fresh metadata');

$rdiffopke->compare_files;
$rdiffopke->transfer_files;

is($metadata_dbh->selectrow_array('select count(*) from rdiffs;'), 1, 'Only 1 rdiff in metadata');
is($metadata_dbh->selectrow_array('select max(rdiff) from rdiffs;'), 1, 'Latest rdiff is 1');
is($metadata_dbh->selectrow_array('select count(*) from files;'), 0, 'Check if metadata files table is empty');
is($metadata_dbh->selectrow_array('select count(*) from paths;'), 0, 'Check if metadata paths table is empty');
is($metadata_dbh->selectrow_array('select count(*) from localfiles;'), 0, 'Check if metadata localfiles table is empty');
is($metadata_dbh->selectrow_array('select count(*) from keys;'), 0, 'Check if metadata keys table is empty');
ok(-f file($repodir->dirname,'metadata')->stringify, 'Metadata file still there');
ok(!-f file($repodir->dirname,'pubkey')->stringify, 'Public key file still not there');
ok(-d dir($repodir->dirname,'data')->stringify, 'data dir present');
ok(-l file($repodir->dirname, 'latest_rdiff')->stringify, 'slink latest_rdiff present');
ok(-l file($repodir->dirname,'data', '_latest_rdiff')->stringify, 'slink latest_rdiff present');
ok(!-e dir($repodir->dirname,'data', '0')->stringify, 'dir for rdiff 0 missing');
ok(!-e dir($repodir->dirname,'data', '1')->stringify, 'dir for rdiff 1 missing');


$rdiffopke->compare_files;
$rdiffopke->transfer_files;

ok(-f file($repodir->dirname,'metadata')->stringify, 'Metadata file still there');
ok(!-f file($repodir->dirname,'pubkey')->stringify, 'Public key file still not there');
ok(-d dir($repodir->dirname,'data')->stringify, 'data dir present');
ok(-l file($repodir->dirname, 'latest_rdiff')->stringify, 'slink latest_rdiff present');
ok(-l file($repodir->dirname,'data', '_latest_rdiff')->stringify, 'slink latest_rdiff present');
ok(!-e dir($repodir->dirname,'data', '0')->stringify, 'dir for rdiff 0 missing');
ok(!-e dir($repodir->dirname,'data', '1')->stringify, 'dir for rdiff 1 missing');
ok(!-e dir($repodir->dirname,'data', '2')->stringify, 'dir for rdiff 2 missing');

is($metadata_dbh->selectrow_array('select count(*) from rdiffs;'), 2, 'Only 2 rdiff in metadata');
is($metadata_dbh->selectrow_array('select max(rdiff) from rdiffs;'), 2, 'Latest rdiff is 2');
is($metadata_dbh->selectrow_array('select count(*) from files;'), 0, 'Check if metadata files table is empty');
is($metadata_dbh->selectrow_array('select count(*) from paths;'), 0, 'Check if metadata paths table is empty');
is($metadata_dbh->selectrow_array('select count(*) from localfiles;'), 0, 'Check if metadata localfiles table is empty');
is($metadata_dbh->selectrow_array('select count(*) from keys;'), 0, 'Check if metadata keys table is empty');

create_file($sourcedir->dirname, 'file1', 'abc');

$rdiffopke->compare_files;
$rdiffopke->transfer_files;

ok(-f file($repodir->dirname,'metadata')->stringify, 'Metadata file still there');
ok(!-f file($repodir->dirname,'pubkey')->stringify, 'Public key file still not there');
ok(-d dir($repodir->dirname,'data')->stringify, 'data dir present');
ok(-l file($repodir->dirname, 'latest_rdiff')->stringify, 'slink latest_rdiff present');
ok(-l file($repodir->dirname,'data', '_latest_rdiff')->stringify, 'slink latest_rdiff present');
ok(!-e dir($repodir->dirname,'data', '0')->stringify, 'dir for rdiff 0 missing');
ok(!-e dir($repodir->dirname,'data', '1')->stringify, 'dir for rdiff 1 missing');
ok(!-e dir($repodir->dirname,'data', '2')->stringify, 'dir for rdiff 2 missing');
ok(-d dir($repodir->dirname,'data', '3')->stringify, 'dir for rdiff 3 exists');
ok(!-e file($repodir->dirname,'data', '2', 'file1')->stringify, 'file1 for rdiff 3 exists');
ok(-f file($repodir->dirname,'data', '3', 'file1')->stringify, 'file1 for rdiff 3 exists');
is($metadata_dbh->selectrow_array('select count(*) from rdiffs;'), 3, 'Only 3 rdiff in metadata');
is($metadata_dbh->selectrow_array('select max(rdiff) from rdiffs;'), 3, 'Latest rdiff is 3');
is($metadata_dbh->selectrow_array('select count(*) from files;'), 1, 'Check if metadata files has 1 record');
is($metadata_dbh->selectrow_array('select count(*) from paths;'), 1, 'Check if metadata paths has 1 record');
is($metadata_dbh->selectrow_array('select count(*) from localfiles;'), 1, 'Check if metadata localfiles has 1 record');
is($metadata_dbh->selectrow_array('select count(*) from keys;'), 0, 'Check if metadata keys table is empty');

my ($path, $type) =$metadata_dbh->selectrow_array("select paths.path, files.type  from files, paths, localfiles where rdiff=3 and  paths.path='file1' and files.path_id=paths.path_id and localfiles.localfile_id=files.localfile_id;");
is($path, 'file1', 'file1 is in repo');
is($type, 'file', 'file1 is type file');
($path) =$metadata_dbh->selectrow_array("select paths.path  from files, paths, localfiles where rdiff=2 and  paths.path='file1' and files.path_id=paths.path_id and localfiles.localfile_id=files.localfile_id;");
is($path, undef, 'file1 is no more in rdiff 2');

unlink file($sourcedir->dirname, 'file1')->stringify;

$rdiffopke->compare_files;
$rdiffopke->transfer_files;

ok(!-e dir($repodir->dirname,'data', '4')->stringify, 'dir for rdiff 4 does not exists');
ok(-d dir($repodir->dirname,'data', '3')->stringify, 'dir for rdiff 3 exists');
ok(-f file($repodir->dirname,'data', '3', 'file1')->stringify, 'file1 for rdiff 3 exists');
($path, $type) =$metadata_dbh->selectrow_array("select paths.path, files.type  from files, paths, localfiles where rdiff=3 and  paths.path='file1' and files.path_id=paths.path_id and localfiles.localfile_id=files.localfile_id;");
is($path, 'file1', 'file1 is in repo rdiff 3');
is($type, 'file', 'file1 is type file');
($path) =$metadata_dbh->selectrow_array("select paths.path  from files, paths, localfiles where rdiff=4 and  paths.path='file1' and files.path_id=paths.path_id and localfiles.localfile_id=files.localfile_id;");
is($path, undef, 'file1 is not in rdiff 4');


my $file1_h=create_file($sourcedir->dirname, 'file1', 'abc');
my $file2_h=create_file($sourcedir->dirname, 'file2', 'blabla');

$rdiffopke->compare_files;
$rdiffopke->transfer_files;

ok(!-e dir($repodir->dirname,'data', '4')->stringify, 'dir for rdiff 4 does not exists');
ok(-d dir($repodir->dirname,'data', '3')->stringify, 'dir for rdiff 3 exists');
ok(-f file($repodir->dirname,'data', '3', 'file1')->stringify, 'file1 for rdiff 3 exists');
($path, $type) =$metadata_dbh->selectrow_array("select paths.path, files.type  from files, paths, localfiles where rdiff=3 and  paths.path='file1' and files.path_id=paths.path_id and localfiles.localfile_id=files.localfile_id;");
is($path, 'file1', 'file1 is in repo rdiff 3');
is($type, 'file', 'file1 is type file');
($path) =$metadata_dbh->selectrow_array("select paths.path  from files, paths, localfiles where rdiff=4 and  paths.path='file1' and files.path_id=paths.path_id and localfiles.localfile_id=files.localfile_id;");
is($path, undef, 'file1 is not in rdiff 4');

ok(-d dir($repodir->dirname,'data', '5')->stringify, 'dir for rdiff 5 exists');
ok(-f file($repodir->dirname,'data', '5', 'file1')->stringify, 'file1 for rdiff 5 exists');
($path, $type) =$metadata_dbh->selectrow_array("select paths.path, files.type  from files, paths, localfiles where rdiff=5 and  paths.path='file1' and files.path_id=paths.path_id and localfiles.localfile_id=files.localfile_id;");
is($path, 'file1', 'file1 is in repo rdiff 5');
is($type, 'file', 'file1 is type file');

ok(-d dir($repodir->dirname,'data', '5')->stringify, 'dir for rdiff 5 exists');
ok(-f file($repodir->dirname,'data', '5', 'file2')->stringify, 'file2 for rdiff 5 exists');
($path, $type) =$metadata_dbh->selectrow_array("select paths.path, files.type  from files, paths, localfiles where rdiff=5 and  paths.path='file2' and files.path_id=paths.path_id and localfiles.localfile_id=files.localfile_id;");
is($path, 'file2', 'file2 is in repo rdiff 5');
is($type, 'file', 'file2 is type file');

$file1_h=create_file($sourcedir->dirname, 'file1', 'something');

$rdiffopke->compare_files;
$rdiffopke->transfer_files;

ok(!-e dir($repodir->dirname,'data', '4')->stringify, 'dir for rdiff 4 does not exists');
ok(-d dir($repodir->dirname,'data', '3')->stringify, 'dir for rdiff 3 exists');
ok(-f file($repodir->dirname,'data', '3', 'file1')->stringify, 'file1 for rdiff 3 exists');
($path, $type) =$metadata_dbh->selectrow_array("select paths.path, files.type  from files, paths, localfiles where rdiff=3 and  paths.path='file1' and files.path_id=paths.path_id and localfiles.localfile_id=files.localfile_id;");
is($path, 'file1', 'file1 is in repo rdiff 3');
is($type, 'file', 'file1 is type file');
($path) =$metadata_dbh->selectrow_array("select paths.path  from files, paths, localfiles where rdiff=4 and  paths.path='file1' and files.path_id=paths.path_id and localfiles.localfile_id=files.localfile_id;");
is($path, undef, 'file1 is not in rdiff 4');

ok(-d dir($repodir->dirname,'data', '5')->stringify, 'dir for rdiff 5 exists');
ok(-f file($repodir->dirname,'data', '5', 'file1')->stringify, 'file1 for rdiff 5 exists');
($path, $type) =$metadata_dbh->selectrow_array("select paths.path, files.type  from files, paths, localfiles where rdiff=5 and  paths.path='file1' and files.path_id=paths.path_id and localfiles.localfile_id=files.localfile_id;");
is($path, 'file1', 'file1 is in repo rdiff 5');
is($type, 'file', 'file1 is type file');

ok(-d dir($repodir->dirname,'data', '6')->stringify, 'dir for rdiff 6 exists');
ok(-f file($repodir->dirname,'data', '6', 'file1')->stringify, 'file1 for rdiff 6 exists');
($path, $type) =$metadata_dbh->selectrow_array("select paths.path, files.type  from files, paths, localfiles where rdiff=6 and  paths.path='file1' and files.path_id=paths.path_id and localfiles.localfile_id=files.localfile_id;");
is($path, 'file1', 'file1 is in repo rdiff 6');
is($type, 'file', 'file1 is type file');

ok(-d dir($repodir->dirname,'data', '6')->stringify, 'dir for rdiff 6 exists');
ok(-f file($repodir->dirname,'data', '6', 'file2')->stringify, 'file2 for rdiff 6 exists');
($path, $type) =$metadata_dbh->selectrow_array("select paths.path, files.type  from files, paths, localfiles where rdiff=6 and  paths.path='file2' and files.path_id=paths.path_id and localfiles.localfile_id=files.localfile_id;");
is($path, 'file2', 'file2 is in repo rdiff 6');
is($type, 'file', 'file2 is type file');

ok(!-e file($repodir->dirname,'data', '5', 'file2')->stringify, 'file2 for rdiff 5 does not exists');
($path) =$metadata_dbh->selectrow_array("select paths.path  from files, paths, localfiles where rdiff=5 and  paths.path='file2' and files.path_id=paths.path_id and localfiles.localfile_id=files.localfile_id;");
is($path, undef, 'file1 is not in rdiff 5');

unlink file($sourcedir->dirname, 'file1')->stringify;
mkdir file($sourcedir->dirname, 'file1')->stringify;

diag("Temp source directory: sdir=".$sourcedir->dirname);
diag("Temp repo directory: rdir=".$repodir->dirname);

$DB::single=1;

$rdiffopke->compare_files;
$rdiffopke->transfer_files;



ok(!-e dir($repodir->dirname,'data', '4')->stringify, 'dir for rdiff 4 does not exists');
ok(-d dir($repodir->dirname,'data', '3')->stringify, 'dir for rdiff 3 exists');
ok(-f file($repodir->dirname,'data', '3', 'file1')->stringify, 'file1 for rdiff 3 exists');
($path, $type) =$metadata_dbh->selectrow_array("select paths.path, files.type  from files, paths, localfiles where rdiff=3 and  paths.path='file1' and files.path_id=paths.path_id and localfiles.localfile_id=files.localfile_id;");
is($path, 'file1', 'file1 is in repo rdiff 3');
is($type, 'file', 'file1 is type file');
($path) =$metadata_dbh->selectrow_array("select paths.path  from files, paths, localfiles where rdiff=4 and  paths.path='file1' and files.path_id=paths.path_id and localfiles.localfile_id=files.localfile_id;");
is($path, undef, 'file1 is not in rdiff 4');

ok(-d dir($repodir->dirname,'data', '5')->stringify, 'dir for rdiff 5 exists');
ok(-f file($repodir->dirname,'data', '5', 'file1')->stringify, 'file1 for rdiff 5 exists');
($path, $type) =$metadata_dbh->selectrow_array("select paths.path, files.type  from files, paths, localfiles where rdiff=5 and  paths.path='file1' and files.path_id=paths.path_id and localfiles.localfile_id=files.localfile_id;");
is($path, 'file1', 'file1 is in repo rdiff 5');
is($type, 'file', 'file1 is type file');

ok(-d dir($repodir->dirname,'data', '6')->stringify, 'dir for rdiff 6 exists');
ok(-f file($repodir->dirname,'data', '6', 'file1')->stringify, 'file1 for rdiff 6 exists');
($path, $type) =$metadata_dbh->selectrow_array("select paths.path, files.type  from files, paths, localfiles where rdiff=6 and  paths.path='file1' and files.path_id=paths.path_id and localfiles.localfile_id=files.localfile_id;");
is($path, 'file1', 'file1 is in repo rdiff 6');
is($type, 'file', 'file1 is type file');

ok(-d dir($repodir->dirname,'data', '7')->stringify, 'dir for rdiff 7 exists');
ok(-f file($repodir->dirname,'data', '7', 'file2')->stringify, 'file2 for rdiff 7 exists');
($path, $type) =$metadata_dbh->selectrow_array("select paths.path, files.type  from files, paths, localfiles where rdiff=7 and  paths.path='file2' and files.path_id=paths.path_id and localfiles.localfile_id=files.localfile_id;");
is($path, 'file2', 'file2 is in repo rdiff 7');
is($type, 'file', 'file2 is type file');

ok(!-e file($repodir->dirname,'data', '6', 'file2')->stringify, 'file2 for rdiff 6 does not exists');
($path) =$metadata_dbh->selectrow_array("select paths.path  from files, paths, localfiles where rdiff=6 and  paths.path='file2' and files.path_id=paths.path_id and localfiles.localfile_id=files.localfile_id;");
is($path, undef, 'file1 is not in rdiff 6');

ok(!-f file($repodir->dirname,'data', '7', 'file1')->stringify, 'file1 (file) for rdiff 7 does not exists');
($path) =$metadata_dbh->selectrow_array("select paths.path  from files, paths where rdiff=7 and  paths.path='file1' and files.path_id=paths.path_id and files.type='file';");
is($path, undef, 'file1 (file) is not in rdiff 7');
($path) =$metadata_dbh->selectrow_array("select paths.path  from files, paths where rdiff=7 and  paths.path='file1' and files.path_id=paths.path_id and files.type='dir';");
is($path, 'file1', 'file1 (dir) is in repo rdiff 7');






done_testing;
