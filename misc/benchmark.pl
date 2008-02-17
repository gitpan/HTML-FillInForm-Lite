#!/usr/bin/perl

use strict;
use warnings;

use FindBin qw($Bin);

use HTML::FillInForm 2.0;
use HTML::FillInForm::Lite;

use Benchmark qw(timethese cmpthese);

if(grep{ $_ eq '--help' } @ARGV){
	print <<'EOT';
benchmark.pl (--smal|--large) [options..]
	--large         processe large content
	--reuse-object  reuse the objects
	--target        with 'target' option
	--scalar        fill in scalar
EOT
	exit;
}

my %param = (
	one   => 'ONE',
	two   => 'TWO',
	three => 'THREE',
	four  => 'C',

	checker  => 'c1',
	selector => 's1',
);

my $file = "$Bin/testform1.html";

my $o1 = 'HTML::FillInForm';
my $o2 = 'HTML::FillInForm::Lite';

if(grep{ $_ eq '--output' } @ARGV){
	print "$o1:\n", $o1->fill($file, \%param);
	print "$o2:\n", $o2->fill($file, \%param);
	exit;
}
elsif(grep{ $_ eq '--large' } @ARGV){
	print "Large content\n";
	$file = "$Bin/testform2.html";
}
else{
	print "Small content\n";
}

my $str  = do{ local $/; open my($fh), $file or die $!; <$fh> };

if(grep{ $_ eq '--reuse-object' } @ARGV){
	print "with --reuse-object\n";
	$o1 = $o1->new();
	$o2 = $o2->new();
}
my @option;

if(grep{ $_ eq '--target' } @ARGV){
	print "with --target\n";
	@option = (target => 'form1');
}


my $source;
if(grep{ $_ eq '--scalar' } @ARGV){
	print "fill in scalar\n";
	$source = \$str;
}
else{
	print "fill in file\n";
	$source = $file;
}


print "\n";
cmpthese timethese 0 => {
	'FIF'      => sub{ $o1->fill($source, \%param, @option) },
	'Lite'     => sub{ $o2->fill($source, \%param, @option) },
};
