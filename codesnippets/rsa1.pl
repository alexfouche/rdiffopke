#!perl

use Crypt::RSA;
use Data::Dumper;



$rsa = Crypt::RSA->new(
    ES  => 'OAEP',
    KF  => 'Native',
    );

($public, $private) = $rsa->keygen( Size => 1024 );

$message = "/some/file/path_on/some/disk/but/there_are/a/lot/of/subdirectories/filename_with_date_and_other_attributes";

if (1==0) {
    $c = $rsa->encrypt( Message => $message, Key => $public );
    print $rsa->errstr unless defined($c);
    $message2 = $rsa->decrypt( Ciphertext => $c, Key => $private );
    print $rsa->errstr unless defined($message2);
    print (Dumper [$c,$message2]);

    print "\n\n\n";
}    

use MIME::Base64;
$c = $rsa->encrypt( Message => $message, Key => $public); 
print $rsa->errstr unless defined($c);
print (Dumper [$c]);
  print "\n";
$encoded = encode_base64($c); chomp $encoded;
$decoded = decode_base64($encoded);
$message2 = $rsa->decrypt( Ciphertext => $decoded, Key => $private );
print $rsa->errstr unless defined($message2);
print (Dumper [$c, $encoded,$decoded, $message2]);



