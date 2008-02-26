#!perl

use strict;
use warnings;
use Test::More;

BEGIN{
	require utf8; # probably noop
	if(not defined &utf8::is_utf8){
		plan skip_all => "require utf8::is_utf8()";
	}
	else{
		plan tests => 4;
	}
}
use encoding 'Shift_JIS';

BEGIN{ use_ok('HTML::FillInForm::Lite') }

use Fatal qw(open close);
use FindBin qw($Bin);
my $file = "$Bin/test_sjis.html";

my $o = HTML::FillInForm::Lite->new();

my $u1  = "\xe9p\xe9k";         # "camel" in Japanese kanji    (Shift_JIS)
my $u2  = "\x83\x89\x83N\x83_"; # "camel" in Japanese katakana (Shift_JIS)

my $x = qr{value="$u1"};

my $in;
open $in, '<:encoding(Shift_JIS)',  $file;
like $o->fill($in,
	{ camel => $u1 }), qr{name="camel" \s+ value="$u1"}xms,
	"Unicode value";

open $in, '<:encoding(Shift_JIS)',  $file;
like $o->fill($in,
	{ $u2 => 'camel' }), qr{name="$u2" \s+ value="camel"}xms,
	"Unicode name";

open $in, '<:encoding(Shift_JIS)',  $file;
like $o->fill($in, { $u2 => $u1 }),
	$x, "Unicode name/value";

close($in);
