###############################
#
# Class:  Rdiffopke::SubTypes
#
###############################

# I create this class because subtypes are in global namespace, so i name my subtypes Rdiffopke::Something

package Rdiffopke::SubTypes;

use Moose;
#use namespace::autoclean; # because attribute 'type' and its accessors conflict with method 'type' of Moose::Util::TypeConstraints
use Moose::Util::TypeConstraints;

subtype 'Rdiffopke::FileType' => as 'Str' =>
    where { $_ =~ 'file' || $_ =~ 'dir' || $_ =~ 'slink' } =>
    message { "FileType is either 'file', 'dir' or 'slink'" };

subtype 'Rdiffopke::PositiveInt' => as 'Int' => where { $_ > 0 } =>
    message { 'Only positive greater than zero integers accepted' };

no Moose;
__PACKAGE__->meta->make_immutable;

1;
