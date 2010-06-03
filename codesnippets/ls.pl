#foreach $i (</Users/alex/*>) { print "$i\n"; }

#if (</Users/alex/*>){ print "alex - there are files\n"; }

#if (</Users/fasdas/*>){ print "fasdas - there are files\n"; }


#if (</Users/vide/*>){ print "vide - there are files\n"; }

$a='/Users/alex';

if (<$a/*>){ print "alex - there are files\n"; }


