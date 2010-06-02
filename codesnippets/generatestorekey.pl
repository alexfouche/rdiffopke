#!perl

use Crypt::RSA::Key;
use Data::Dumper;


my $keychain = new Crypt::RSA::Key;
my ($public, $private) = $keychain->generate ( 
                              Identity  => 'Alexandre Fouche <alexandre.fouche@gmail.com>',
                              Size      => 1024,  
                            #  Password  => 'A day so foul & fair', 
                              Verbosity => 0,
                              KF    => 'Native',
                              ES    =>'OAEP',
#                              Filename => 'rsakey'
                             ) or die $keychain->errstr();
print (Dumper [$public, $private]);
print "\n\n\n\n\n";                             
#my ($public2, $private2) = $keychain->generate ( 
#                              Identity  => 'Alexandre Fouche <alexandre.fouche@gmail.com>',
#                              Size      => 1024,  
                            #  Password  => 'A day so foul & fair', 
#                              KF    => 'SSH',
#                              Verbosity => 0,
#                              Filename => 'rsakey2'
#                             ) or die $keychain->errstr();
#print (Dumper [$public2, $private2]);


use Convert::PEM;

my $keyfile = 'rsa.pem';
my $pem = Convert::PEM->new(
                   Name => "RSA PRIVATE KEY",
  ASN  => qq(
                  RSAPrivateKey SEQUENCE {
                      version INTEGER,
                      n INTEGER,
                      e INTEGER,
                      d INTEGER,
                      p INTEGER,
                      q INTEGER,
                      dp INTEGER,
                      dq INTEGER,
                      iqmp INTEGER
                  }
                  )
);

#    $pem->write(
#                   Content  => $private{private},
#                #   Password => $pwd,
#                   Filename => $keyfile
#             );
#    print $pem->errstr;

