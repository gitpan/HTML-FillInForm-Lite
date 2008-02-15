#!perl

use strict;
use warnings;
use Test::More tests => 3;

BEGIN{ use_ok('HTML::FillInForm::Lite') }

my $o = HTML::FillInForm::Lite->new();

my($s, $x);
{
	use utf8;

	# "camel" in Japanese katakana and kanji
	$s =  q{<input name="ラクダ" value="xxx" />};
	$x = qr{value="駱駝"};
	like $o->fill(\$s, { 'ラクダ' => '駱駝' }), $x, "Unicode name/value";
}

sub my_param{
	my $camel = '駱駝';
	utf8::decode($camel); # decode to the perl native unicode form
	return $camel;
}
SKIP:{
	skip "utf8::decode not supported in 5.6.x", 1, if $] < 5.008;


	like $o->fill(\$s, \&my_param), $x, "convert in param()";
}
