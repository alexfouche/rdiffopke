  use Net::FTP::File;

   my $ftp = Net::FTP->new("fredericbleu.com", Debug => 0)
      or die "Cannot connect to fredericbleu.com: $@";

    $ftp->login('frederic@fredericbleu.com','qwerty9561')
      or die "Cannot login ", $ftp->message;

#   if($ftp->isfile($file) {
#      $ftp->move($file,$newfile) or warn $ftp->message;
#      $ftp->chmod(644, $newfile) or warn $ftp->message;
#   } else { print "$file does not exist or is a directory"; }

$ftp->ls;

$ftp->cwd('/can_be_deleted');
   $ftp->pretty_dir(0);
 $ftp->dir_hashref(); # [a-z_]+ version

   $ftp->pretty_dir(1);   
 $ftp->dir_hashref(); # "Pretty" version

   
   
   $ftp->quit;
   
   
exit 0;

__DATA__

NOT PRETTY

  DB<2> x $ftp->dir_hashref();
0  HASH(0x100a5c0e0)
   '.' => HASH(0x100a1e1c0)
      'Link To' => undef
      'bytes' => 4096
      'day' => 31
      'group' => 'frederic'
      'links' => 3
      'month' => 'May'
      'owner' => 'frederic'
      'path' => '.'
      'perms' => 'drwxr-xr-x'
      'yr_tm' => '02:39'
   '..' => HASH(0x100a5c470)
      'Link To' => undef
      'bytes' => 4096
      'day' => 31
      'group' => 'frederic'
      'links' => 10
      'month' => 'May'
      'owner' => 'frederic'
      'path' => '..'
      'perms' => 'drwx--x--x'
      'yr_tm' => '02:38'
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

      
      
PRETTY

     DB<4> x $ftp->dir_hashref();
0  HASH(0x100a1df08)
   '.' => HASH(0x100a5c860)
      'Bytes' => 4096
      'Group' => 'frederic'
      'Last Modified Day' => 31
      'Last Modified Month' => 'May'
      'Last Modified Year/Time' => '02:39'
      'Link To' => undef
      'Number of Links' => 3
      'Owner' => 'frederic'
      'Path' => '.'
      'Permissions' => 'drwxr-xr-x'
   '..' => HASH(0x100a5c938)
      'Bytes' => 4096
      'Group' => 'frederic'
      'Last Modified Day' => 31
      'Last Modified Month' => 'May'
      'Last Modified Year/Time' => '02:38'
      'Link To' => undef
      'Number of Links' => 10
      'Owner' => 'frederic'
      'Path' => '..'
      'Permissions' => 'drwx--x--x'
   'discount.php' => HASH(0x100a54e78)
      'Bytes' => 675
      'Group' => 'frederic'
      'Last Modified Day' => 11
      'Last Modified Month' => 'Aug'
      'Last Modified Year/Time' => 2009
      'Link To' => undef
      'Number of Links' => 1
      'Owner' => 'frederic'
      'Path' => 'discount.php'
      'Permissions' => '-rwxr-xr-x'
   'docs' => HASH(0x100a5c560)
      'Bytes' => 4096
      'Group' => 'frederic'
      'Last Modified Day' => 31
      'Last Modified Month' => 'May'
      'Last Modified Year/Time' => '04:18'
      'Link To' => undef
      'Number of Links' => 2
      'Owner' => 'frederic'
      'Path' => 'docs'
      'Permissions' => 'drwxr-xr-x'

   
