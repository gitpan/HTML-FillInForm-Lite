#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 10;

BEGIN{ use_ok('HTML::FillInForm::Lite') }


my %q = (
	foo => 'bar',
);


my $o = HTML::FillInForm::Lite->new();

my $x = qr{<option selected="selected">\s*bar\s*</option>};
like $o->fill(\ qq{<select name="foo"><option>bar</option></select>}, \%q),
	$x,
	  	  "select an option (no white-space)";
like $o->fill(\ qq{<select name='foo'><option>bar</option></select>}, \%q),
	$x,
	  	  "select an option (single-quoted name)";
like $o->fill(\ qq{<select name=foo><option>bar</option></select>}, \%q),
	$x,
	  	  "select an option (unquoted name)";

like $o->fill(\ qq{<select name="foo">
			<option>
				bar
			</option>
		</select>}, \%q),
	$x,
	  	  "select an option (including many white spaces)";


is $o->fill(\ qq{<select name="foo"><option>bar</option></select>}, \%q, ignore_types => ['select']),
	      qq{<select name="foo"><option>bar</option></select>},
	  	  "ignore select";

is $o->fill(\ qq{<select name="foo"><option>bar</option></select>}, {foo => undef}),
	      qq{<select name="foo"><option>bar</option></select>},
	  	  "nothing with undef data";

is $o->fill(\ qq{<select name="foo"><option value="bar">ok</option></select>}, \%q),
	      qq{<select name="foo"><option value="bar" selected="selected">ok</option></select>},
	 	   "select an option with 'value=' attribute";

is $o->fill(\ qq{<select name="foo"><option value="bar">ok</option><option value="baz" selected="selected">ng</option></select>}, \%q),
	      qq{<select name="foo"><option value="bar" selected="selected">ok</option><option value="baz">ng</option></select>},
	    	"chenge the selected";

like $o->fill(\ qq{<select name="foo"><option value="bar">ok</option><option value="baz" selected="selected">ok</option></select>},
		{ foo => [qw(bar baz)] }),
	      qr{value="bar"\s+selected="selected".*value="baz"\s+selected="selected"},
	    	"select multiple options";


