#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 6;

BEGIN{ use_ok('HTML::FillInForm::Lite') }


my %q = (
	foo => 'bar',
);


my $o = HTML::FillInForm::Lite->new();

is $o->fill(\ qq{<select name="foo"><option>bar</option></select>}, \%q),
	      qq{<select name="foo"><option selected="selected">bar</option></select>},
	  	  "select an option";
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

