#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 9;

BEGIN{ use_ok('HTML::FillInForm::Lite') }


my %q = (
	foo => 'bar',
);


my $o = HTML::FillInForm::Lite->new();


is $o->fill(\qq{<textarea name="foo">xxx</textarea>}, \%q),
	     qq{<textarea name="foo">bar</textarea>}, "fill textarea";

is $o->fill(\qq{<textarea name="foo">xxx</textarea>}, [{}, \%q]),
	     qq{<textarea name="foo">bar</textarea>}, "fill textarea with array data";

	     
is $o->fill(\qq{<textarea name="bar">xxx</textarea>}, \%q),
	     qq{<textarea name="bar">xxx</textarea>}, "doesn't fill textarea with unmatched name";
is $o->fill(\qq{<textarea name="foo">xxx</textarea>}, \%q, ignore_types => ['textarea']),
	     qq{<textarea name="foo">xxx</textarea>}, "ignore textarea";

is $o->fill(\qq{<textarea name="foo">xxx</textarea>}, { foo => '<foo> & <bar>' }),
	     qq{<textarea name="foo">&lt;foo&gt; &amp; &lt;bar&gt;</textarea>}, "html-escape";

is $o->fill(\qq{<textarea name="foo">xxx</textarea>}, { foo => '' }),
	     qq{<textarea name="foo"></textarea>}, "empty textarea";

is $o->fill(\qq{<textarea name="foo">xxx</textarea>}, { foo => undef }),
	     qq{<textarea name="foo">xxx</textarea>}, "{ NAME => undef } is ignored";

is $o->fill(\qq{<textarea name="foo">xxx}, \%q),
	     qq{<textarea name="foo">xxx}, "ignore syntax error";

