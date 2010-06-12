use Rdiffopke::File;
use Rdiffopke::FileList;
use Data::Dumper; 
use File::stat;
use Rdiffopke::File::_LocalFile;
use strict;


my $stat = stat('/Users/alex/bin/vapartout');
print Dumper($stat);

my $file_list  = Rdiffopke::FileList->new;
my $i;
for ($i = 0, $i<10000, $i++) {
	 $file_list->add('something/which/$i/looks/like/a/path',
            Rdiffopke::File::_LocalFile->new(
				rel_path=>'something/which/$i/looks/like/a/path',
                path => 'This/is/the/complete/something/which/$i/looks/like/a/path/',
                mode => 342,
                uid  => 501,
                gid  => 501,
                size => 4328429+$i,
                mtime => 1267445910+$i,
				type =>'file',
            )
);
	
}

