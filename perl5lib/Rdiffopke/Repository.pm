
###############################
    #
    # Class:  Rdiffopke::Repository
    #
###############################

package Rdiffopke::Repository;

use Moose;
use Rdiffopke::Metadata;
use Rdiffopke::Userkey;
   
has 'userkey' =>(is=>'ro', isa=>'Rdiffopke::Userkey' );
has 'metadata' =>(is=>'ro', isa=>'Rdiffopke::Metadata' );
has 'dir' =>  ( is => 'wo', isa => 'Str', required => 1,  );
has 'verbose'  => ( is => 'ro', isa => 'Bool', default => 0 );
has 'no_encryption' => ( is => 'rw', isa => 'Bool', default => 0 );



    Rdiffopke::Repository->mk_ro_accessors
      qw( diff _dir _verbose _no_encryption metadata userkey);

    sub new {
        my $class = shift;
        my %params = @_;
        return unless ( defined $params{dir} );
        return bless {
            _dir                 => $params{dir},
            error_code           => 0,
            _verbose             => $params{verbose},
            _no_encryption       => $params{no_encryption},
            _upgrade_metadata_to => $params{upgrade_metadata_to},
        };

    }

    sub init {
        my $self = shift;

        if ( -e $self->_dir && !-d $self->_dir ) {
            $self->error(12);
            return 0;

        }
        else {
            verbose_message(
                "Creating local reverse-diffs directory '$self->_dir'")
              if ( $self->_verbose );
            mkdir $self->_dir;
        }

        unless ( -d $self->_dir
            && -x $self->_dir
            && -w $self->_dir )
        {
            $self->error_code(2);
            return 0;
        }

        my $userkey = Rdiffopke::Userkey->new(
            dir     => $self->_dir,
            verbose => $self->_verbose
        );
        my $metadata = Rdiffopke::Metadata->new(
            dir     => $self->_dir,
            verbose => $self->_verbose
        );

#  if (! $userkey->exists && !$self->_no_encryption && </Users/alex/tmp/rdiffopke/*> ) {
        my $tmp = $self->_dir;
        if ( !$userkey->exists && !$self->_no_encryption && <$tmp/*> ) {
            $self->error_code(3);
            return 0;
        }

        if ( $self->_no_encryption && -e $userkey->exists ) {
            $self->error_code(4);
            return 0;
        }

        if (   $metadata->exists
            && !$userkey->exists
            && !$self->_no_encryption )
        {
            $self->error_code(5);
            return 0;
        }

        unless ( $self->_no_encryption ) {
            unless ( $userkey->init ) {
                $self->error_code( $userkey->error_code );
                return 0;
            }
        }


        unless (
            $metadata->init( upgrade_to => $self->{_upgrade_metadata_to} ) )
        {
            $self->error_code( $metadata->error_code );
            return 0;
        }

        $self->{metadata} = $metadata;
        $self->{userkey}  = $userkey;

        return 1;    # Returns true;
    }

    sub close {
        my $self = shift;
        $self->metadata->close if ( defined $self->metadata );
    }

    sub schema_version {
        my $self = shift;
        return $self->metadata->schema_version;
    }

    sub set_message {
        my ( $self, $message ) = @_;
        $DB::single = 1;
        $self->metadata->set_message($message) if ( $self->metadata );
    }

    1;

