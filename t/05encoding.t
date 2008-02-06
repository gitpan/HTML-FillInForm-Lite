#!perl

use strict;
use warnings;
use Test::More tests => 3;

BEGIN{ use_ok('HTML::FillInForm::Lite') }

my $o = HTML::FillInForm::Lite->new();

use utf8;

is $o->fill(\q{<input name="ラクダ" value="xxx" />}, { 'ラクダ' => '駱駝' }),
	    q{<input name="ラクダ" value="駱駝" />}, "Unicode name/value";

my $s = '';
open my($fh), '>:utf8', \$s or die "Cannot open scalar: $!";

print {$fh} $o->fill(\q{<input name="ラクダ" value="xxx" />}, { 'ラクダ' => '駱駝' });

no utf8;

is $s, q{<input name="ラクダ" value="駱駝" />}, "Unicode name/value (output)";

