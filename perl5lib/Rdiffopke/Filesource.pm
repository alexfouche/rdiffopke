
###############################
    #
    # Class:  Rdiffopke::Filesource
    #
###############################


    package Rdiffopke::Filesource;
use Moose;

use Rdiffopke::FileSource::_Localdir



has 'url'=>(is=>'ro', isa=>'Str',required => 1,);
has 'verbose'=>(is=>'ro', isa=>'Bool', default => 0);


# Rdiffopke::Filesource->new gets an URL and return an initialized object of a relevant derived class, depending of URL parameter
    sub new {
        my $class  = shift;
        my %params = @_;
      

        #   case $url
        #match ^ftp://

        return Rdiffopke::Filesource::_Localdir->new(
            dir      => $params{url},
            _verbose => $params{verbose}
        );

    }

    sub prepare {
    }

    sub get_detailed_file_list {
     	  die "This function should be overwritten"
    }

   	no Moose;
	  __PACKAGE__->meta->make_immutable;