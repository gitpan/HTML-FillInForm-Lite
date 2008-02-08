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

my $str  = do{ local $/; open my($fh), "$Bin/testform1.html" or die $!; <$fh> };

my $o1 = HTML::FillInForm->new();
my $o2 = HTML::FillInForm::Lite->new();

if(grep{ $_ eq '--output-test' } @ARGV){
	print $o1->fill(\$str, \%param);
	print $o2->fill(\$str, \%param);
	exit;
}

print "Small content ('(t)' means 'with Target'):\n";
cmpthese timethese 0 => {
	'FIF'      => sub{ $o1->fill(\$str, \%param) },
	'Lite'     => sub{ $o2->fill(\$str, \%param) },

	'FIF(t)'   => sub{ $o1->fill(\$str, \%param, target => 'form1') },
	'Lite(t)'  => sub{ $o2->fill(\$str, \%param, target => 'form1') },
};



$str = do{ local $/; open my($fh), "$Bin/testform2.html" or die $!; <$fh> };
print "Large content (from a file):\n";
cmpthese timethese 0 => {
	'FIF'       => sub{ $o1->fill(\$str, \%param) },
	'Lite'      => sub{ $o2->fill(\$str, \%param) },
};
