#!/usr/bin/perl

# Usage: benchmark.pl [--output-test] [--large-content]

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

my $file = "$Bin/testform1.html";

my $o1 = HTML::FillInForm->new();
my $o2 = HTML::FillInForm::Lite->new();

if(grep{ $_ eq '--output-test' } @ARGV){
	print $o1->fill($file, \%param);
	print $o2->fill($file, \%param);
	exit;
}
elsif(grep{ $_ eq '--large-content' } @ARGV){
	print "Large content";
	$file = "$Bin/testform2.html";
}
else{
	print "Small content";
}

my $str  = do{ local $/; open my($fh), $file or die $!; <$fh> };

print " ('(t)' means 'with Target'):\n";
cmpthese timethese 0 => {
	'FIF'      => sub{ $o1->fill(\$str, \%param) },
	'Lite'     => sub{ $o2->fill(\$str, \%param) },

	'FIF(t)'   => sub{ $o1->fill(\$str, \%param, target => 'form1') },
	'Lite(t)'  => sub{ $o2->fill(\$str, \%param, target => 'form1') },
};

