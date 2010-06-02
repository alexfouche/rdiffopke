  use Net::FTP::File;
  use Data::Dumper;
  use Date::Manip;
use strict;

   my $ftp = Net::FTP->new("fredericbleu.com", Debug => 0)
      or die "Cannot connect to fredericbleu.com: $@";

    $ftp->login('frederic@fredericbleu.com','qwerty9561')
      or die "Cannot login ", $ftp->message;

#   if($ftp->isfile($file) {
#      $ftp->move($file,$newfile) or warn $ftp->message;
#      $ftp->chmod(644, $newfile) or warn $ftp->message;
#   } else { print "$file does not exist or is a directory"; }

   $ftp->pretty_dir(0);

my %all_files = ();

#&recursive_ls('/can_be_deleted');
&recursive_ls('/');

#enter recursive   

sub recursive_ls {
   my $absdir = shift;
   $absdir =~ s#^//#/#;
   my @dirs = (); 
   my $ls = $ftp->dir_hashref($absdir); # [a-z_]+ version
   
   sub add_to_all_files {
       my ($absdir, $filedetails) = @_;
       $all_files{$absdir .'/'. $filedetails->{path}} = {
           bytes=>$filedetails->{bytes},
           date=>UnixDate(ParseDateString("$filedetails->{day} $filedetails->{month} $filedetails->{yr_tm}"),"%Y-%m-%d %H:%M:%S"),
           target=>$filedetails->{'Link To'},
           type=>substr ($filedetails->{perms},0,1),
           group=>$filedetails->{group},
           owner=>$filedetails->{owner},
           perms=>$filedetails->{perms},
       };
       $all_files{epoch}= UnixDate($all_files{date},"%s");

   }
   
   foreach my $filename (keys %$ls) {
   $filename =~ s#^//#/#;
       if ($ls->{$filename}->{perms} =~ /^d/ ){
           # Directory
           if ( $filename ne '.' && $filename ne '..') {
               push  @dirs, $filename;
           add_to_all_files($absdir, $ls->{$filename});
           }
       } elsif ($ls->{$filename}->{perms} =~ /^l/) {
           # symlink
           add_to_all_files($absdir, $ls->{$filename});
       } elsif( $ls->{$filename}->{perms} =~ /^\-/) {
           # file
           add_to_all_files($absdir, $ls->{$filename});
       } else {
           # File not supported
       }
       
   }
    
   foreach my $filename (@dirs) {   
       recursive_ls("$absdir/$filename");
       }
       
   }
   
   
   $ftp->quit;
   
   print (Dumper\%all_files);
   
exit 0;



__DATA__
   'discount.php' => HASH(0x100a5c920)
      'Link To' => undef
      'bytes' => 675
      'day' => 11
      'group' => 'frederic'
      'links' => 1
      'month' => 'Aug'
      'owner' => 'frederic'
      'path' => 'discount.php'
      'perms' => '-rwxr-xr-x'
      'yr_tm' => 2009
   'docs' => HASH(0x100a1de60)
      'Link To' => undef
      'bytes' => 4096
      'day' => 31
      'group' => 'frederic'
      'links' => 2
      'month' => 'May'
      'owner' => 'frederic'
      'path' => 'docs'
      'perms' => 'drwxr-xr-x'
      'yr_tm' => '04:18'
