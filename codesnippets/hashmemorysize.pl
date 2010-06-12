use Rdiffopke::File;
use Rdiffopke::FileList;
use Data::Dumper;
use File::stat;
use Rdiffopke::File::_LocalFile;
use strict;
use Devel::Size  qw(size total_size);
#use B::Size ();

my $nb = shift @ARGV;
die "need number parameter\n" unless (defined $nb);

my $stat = stat('/Users/alex/bin/rsync_from_cpanel');
#print Dumper($stat);

print "\n\n\n\n";

my $file_list  = Rdiffopke::FileList->new;
my $i;
for ($i = 1; $i<=$nb; $i++) {
         $file_list->add("something/which/$i/looks/like/a/path",
            Rdiffopke::File::_LocalFile->new(
                                rel_path=>"something/which/$i/looks/like/a/path",
                path => "This/is/the/complete/something/which/$i/looks/like/a/path/",
                mode => 342,
                uid  => 501,
                gid  => 501,
                size => 4328429+$i,
                mtime => 1267445910+$i,
                                type =>'file',
            )
);
}
print scalar(keys %$file_list) ." keys\n";
print total_size($file_list) ." total_size of hash\n";
print size($file_list) ." size of hash\n";

print "\n Now the same but with f instead of file";
$file_list  = Rdiffopke::FileList->new;
for ($i = 1; $i<=$nb; $i++) {
         $file_list->add("something/which/$i/looks/like/a/path",
            Rdiffopke::File::_LocalFile->new(
                                rel_path=>"something/which/$i/looks/like/a/path",
                path => "This/is/the/complete/something/which/$i/looks/like/a/path/",
                mode => 342,
                uid  => 501,
                gid  => 501,
                size => 4328429+$i,
                mtime => 1267445910+$i,
                                type =>'f',
            )
);
}
print scalar(keys %$file_list) ." keys\n";
print total_size($file_list) ." total_size of hash\n";
print size($file_list) ." size of hash\n";

print "\n Now the same but array in File";
$file_list  = Rdiffopke::FileList->new;
for ($i = 1; $i<=$nb; $i++) {
	 $file_list->add("something/which/$i/looks/like/a/path",
		 Rdiffopke::File::_LocalFile->new(
                             rel_path=>"something/which/$i/looks/like/a/path",
             path => "This/is/the/complete/something/which/$i/looks/like/a/path/",
             mode => [342,501,501, 4328429+$i,1267445910+$i,'file']
                             
         )
	);
	}

	print scalar(keys %$file_list) ." keys\n";
print total_size($file_list) ." total_size of hash\n";
print size($file_list) ." size of hash\n";


