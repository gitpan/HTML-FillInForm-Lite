#!/usr/bin/perl

use strict;
use warnings;

use FindBin qw($Bin);

use HTML::FillInForm 2.0;
use HTML::FillInForm::Lite;

use Benchmark qw(timethese cmpthese);

my %param = (
	one   => 'ONE',
	two   => 'TWO',
	three => 'THREE',
	four  => 'C',

	checker  => 'c1',
	selector => 's1',
);

my $str  = do{ local $/; open my($fh), "$Bin/form1.html" or die $!; <$fh> };

my $o1 = HTML::FillInForm->new();
my $o2 = HTML::FillInForm::Lite->new();


print "Small content ('(t)' means 'with Target'):\n";
cmpthese timethese 0 => {
	'FIF'      => sub{ $o1->fill(\$str, \%param) },
	'Lite'     => sub{ $o2->fill(\$str, \%param) },

	'FIF(t)'   => sub{ $o1->fill(\$str, \%param, target => 'form1') },
	'Lite(t)'  => sub{ $o2->fill(\$str, \%param, target => 'form1') },
};



$str = do{ local $/; open my($fh), "$Bin/form2.html" or die $!; <$fh> };
print "Large content (from a file):\n";
cmpthese timethese 0 => {
	'FIF'       => sub{ $o1->fill(\$str, \%param) },
	'Lite'      => sub{ $o2->fill(\$str, \%param) },
};
