#!perl

use Crypt::OpenSSL::RSA;
use MIME::Base64;
use Convert::PEM;
use Data::Dumper;
#use strict;

$priv = Crypt::OpenSSL::RSA->generate_key(128);
@c = $priv->get_key_parameters;
print (Dumper \@c);
#foreach (@c) { print (Dumper $_->to_decimal); }
%priv_components = (
    n=>$c[0],
    e=>$c[1],
    d=>$c[2],
    p=>$c[3],
    q=>$c[4],
    dp=>$c[5],
    dq=>$c[6],
    iqmp=>$c[7],
    );

 my $pem = Convert::PEM->new(
                              Name => 'RSA PRIVATE KEY',
                              ASN  => qq(RSAPrivateKey SEQUENCE {
                      n INTEGER,
                      e INTEGER,
                      d INTEGER,
                      p INTEGER,
                      q INTEGER,
                      dp INTEGER,
                      dq INTEGER,
                      iqmp INTEGER
                  }
           ));
$blob = $pem->encode(Content=>\%priv_components, );
print $pem->errstr;
print (Dumper $blob);
 
 
exit 0;
__DATA__

my $public_key = 'public.pem';
my $string = "/some/file/path_on/some/disk/but/there_are/a/lot/of/subdirectories/filename_with_date_and_other_attributes";

print encryptPublic($public_key,$string);

exit;

sub encryptPublic {
  my ($public_key,$string) = @_;

  my $key_string;
  open(PUB,$public_key) || die "$public_key: $!";
  read(PUB,$key_string,-s PUB); # Suck in the whole file
  close(PUB);

  my $public =
          Crypt::OpenSSL::RSA->new_public_key($key_string);
  encode_base64($public->encrypt($string));
}







my $private_key = 'private.pem';


print decryptPrivate($private_key,$password,$encrypted_string),  "\n";

exit;

sub decryptPrivate {
  my ($private_key,$password,$string) = @_;
  my $key_string = readPrivateKey($private_key,$password);

  return(undef) unless ($key_string); # Decrypt failed.
  my $private = Crypt::OpenSSL::RSA->new_private_key($key_string) ||
  die "$!";

  $private->decrypt(decode_base64($string));
}

sub readPrivateKey {
  my ($file,$password) = @_;
  my $key_string;
  $key_string = decryptPEM($file,$password);
}

sub decryptPEM {
  my ($file,$password) = @_;

  my $pem = Convert::PEM->new(
                              Name => 'RSA PRIVATE KEY',
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
           ));

  my $pkey =
    $pem->read(Filename => $file, Password => $password);

  return(undef) unless ($pkey); # Decrypt failed.
  $pem->encode(Content => $pkey);
}
