use Path::Class;
use File::stat;
use Data::Dumper;
use FileHandle;

# rm -rf /Users/alex/tmp/rien
# mkdir -p  /Users/alex/tmp/rien/{a,b,c}/{d,e,f}
# mkdir -p  /Users/alex/tmp/rien/a/d/g/h/i/j
# touch /Users/alex/tmp/rien/a/f1 /Users/alex/tmp/rien/a/d/g/f2

$dir = dir('/Users/alex/tmp/rien');
$abs = $dir->absolute;
print ref($abs) . " $abs\n";
$rel = $dir->relative;
print ref($rel) . " $rel \n";

sub do_something {
	$thing = shift @_;
	$st = $thing->lstat;
	$remote_items{"$thing"} = {mode=> $st->mode, uid=>$st->uid, gid=>$st->gid, size=> $st->size, mtime=>scalar(gmtime($st->mtime)), type=>($thing->is_dir)?'dir':'file', }

#	print gmtime($st->mtime) . " " . $thing ."\n";
#	print $st->size . " " . $thing ."\n";
#print (Dumper $st);	
}

$dir = dir('/Users/alex/tmp/rien')->absolute;
%remote_items = ();
$dir->recurse( callback => \&do_something );

	print (Dumper \%remote_items);	


foreach my $filename (keys %remote_items ) {
	
	if ($remote_items{$filename}->{type} eq 'file') {
		$source = FileHandle->new($filename, 'r');
		$dest = FileHandle->new($filename . '-copy', 'w');
		while( $bytes = $source->read ( $buf, 1024^2)) {
			unless (print $dest $buf ) {die "Error while writing file";};
		}
		unless (defined $bytes) {die "Error while reading file"}
		$source->close;
		$dest->close;
		
	}
	
	
}	
	
	
