#!perl

use strict;
use warnings;
use Test::More;

BEGIN{
	if($] < 5.008){
		my $v = $] > 5.006 ? sprintf('%vd', $^V) : $];
		plan skip_all => "for 5.8-style unicode semantics";
	}
	else{
		plan tests => 6;
	}
}

BEGIN{ use_ok('HTML::FillInForm::Lite') }

my $o = HTML::FillInForm::Lite->new();

my($s1, $s2, $x);
{
	use utf8;
	# "camel" in Japanese
	$x = qr{value="駱駝"};

	$s1 = q{<input name="camel" value="xxx" />};
	like $o->fill(\$s1,
		{ camel => '駱駝' }), $x, "Unicode value";

	like $o->fill(\q{<input name="ラクダ" value="xxx" />},
		{ 'ラクダ' => 'camel' }), qr/value="camel"/, "Unicode name";

	$s2 =  q{<input name="ラクダ" value="xxx" />};
	like $o->fill(\$s2, { 'ラクダ' => '駱駝' }), $x, "Unicode name/value";
}

sub my_param{
	my $camel = '駱駝';
	utf8::decode($camel); # decode to the perl native unicode form
	return $camel;
}

like $o->fill(\$s1, \&my_param), $x, "unicodize in param()";
like $o->fill(\$s2, \&my_param), $x, "unicodize in param()";

