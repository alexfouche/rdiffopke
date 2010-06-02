#!perl

use Net::FTP::Recursive;
  use FileHandle;
use Data::Dumper;

     $fh = FileHandle->new;
     $fh->fdopen (STDOUT, "w");
    if (defined $fh) {
        print $fh "bar\n";

        sub do_something {
            print (Dumper \@_);
#        print "do_something: I received $_
        }
        
    $ftp = Net::FTP::Recursive->new("fredericbleu.com", Debug => 0, IsPlainFile => 1, IsDirectory => 1, IsSymlink => 1);
    $ftp->login('frederic@fredericbleu.com','qwerty9561');
  #  $ftp->cwd('/');
    $ftp->cwd('/can_be_deleted');
    $ftp->rls( Filehandle => $fh, PrintType => 1 , ParseSub => \&do_something);
    $ftp->quit;

            $fh->close;
    }

