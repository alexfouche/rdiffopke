
use Crypt::OpenSSL::RSA;
use Convert::PEM;

my $key_string = readPrivateKey('/Users/alex/.ssh/id_rsa', '8y2re4weh1');
my $private = Crypt::OpenSSL::RSA->new_private_key($key_string) || die "$!";
# Read your cyphertext into $buffer
my $plaintext = $private->decrypt($buffer);

exit;

sub readPrivateKey {
  my ($file,$password) = @_;
  my $key_string;

  if (!$password) {
    open(PRIV,$file) || die "$file: $!";
    read(PRIV,$key_string,-s PRIV); # Suck in the whole file
    close(PRIV);
  } else {
    $key_string = decryptPEM($file,$password);
  }
  $key_string
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

  $pem->encode(Content => $pkey);
}

