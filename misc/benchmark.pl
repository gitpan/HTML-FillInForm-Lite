#!/usr/bin/perl
# Usage: benchmark.pl --help
use 5.006_000;
use strict;
use warnings;

use FindBin qw($Bin);

use Benchmark qw(timethese cmpthese);


printf "[Perl v%vd]\n", $^V;


if(grep{ $_ eq '--help' } @ARGV){
	print <<'EOT';
benchmark.pl [options..]

	--file          fills in a file [DEFAULT]
	--scalar        fills in a scalar

	--small         fills in only a small form [DEFAULT]
	--large         fills in a full HTML file

	--target        fills with -target option

	--class         calls fill() as a class method [DEFAULT]
	--instance      calls fill() as a instance method
EOT
	exit;
}

{
	my $start = Benchmark->new;
	require HTML::FillInForm;
	printf "load HTML::FillInForm (v%s):\n   %s.\n",
		HTML::FillInForm->VERSION,
		Benchmark->new->timediff($start)->timestr;

	$start = Benchmark->new;
	require HTML::FillInForm::Lite;
	printf "load HTML::FillInForm::Lite (v%s):\n   %s.\n",
		HTML::FillInForm::Lite->VERSION,
		Benchmark->new->timediff($start)->timestr;
}
print "\n";

my %param = (
	one   => '<ONE>',
	two   => '<TWO>',
	three => '<THREE>',
	four  => '<FOUR>',
	five  => '<FIVE>',
	six   => '<SIX>',
	seven => '<SEVEN>',
	eight => '<EIGHT>',

	c => ['c3', 'c4', 'c5'],
	r => 'r3',
	s => 's3',
);

my $file = "$Bin/testform1.html";

my $o1 = 'HTML::FillInForm';
my $o2 = 'HTML::FillInForm::Lite';

if(grep{ $_ eq '--output' } @ARGV){
	print "$o1:\n", $o1->fill($file, \%param);
	print "$o2:\n", $o2->fill($file, \%param);
	exit;
}

my $info;
if(grep{ $_ eq '--large' } @ARGV){
	$info = "large content (full HTML file)";
	$file = "$Bin/testform2.html";
}
else{
	$info = "small content (only a small form)";
}

my $str  = do{ local $/; open my($fh), $file or die $!; <$fh> };

my @option;

if(grep{ $_ eq '--target' } @ARGV){
	print "with --target\n";
	@option = (target => 'form1');
}

if(grep{ $_ eq '--instance' } @ARGV){
	$o1 = $o1->new(@option);
	$o2 = $o2->new(@option);
	@option = ();
}

my $source;
if(grep{ $_ eq '--scalar' } @ARGV){
	print "Fills in a scalar of $info\n";
	$source = \$str;
}
else{
	print "Fills in a file of $info\n";
	$source = $file;
}


print "\n";
cmpthese timethese -2 => {
	'FIF'      => sub{ $o1->fill($source, \%param, @option) },
	'Lite'     => sub{ $o2->fill($source, \%param, @option) },
};
