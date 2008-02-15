#!perl

use strict;
use warnings;
use Test::More tests => 34;

BEGIN{ use_ok('HTML::FillInForm::Lite'); }

BEGIN{
	# import utilities

	no strict 'refs';
	foreach my $f(qw(get_name get_type get_id get_value extract)){
		*$f = \&{'HTML::FillInForm::Lite::_' . $f};
	}
}

my $o = HTML::FillInForm::Lite->new();

ok ref($o), "new() is ok";
isa_ok $o, 'HTML::FillInForm::Lite';

my $s = q{<input type="text" name="foo" value="bar" id="baz" />};

is get_type($s), "text", "(1)_get_type()";
is get_name($s), "foo",  "(1)_get_name()";
is get_id  ($s), "baz",  "(1)_get_id()";
is get_value($s),"bar",  "(1)_get_value()";

$s = q{<input type='text' name='foo' value='bar' id='baz' />};

is get_type($s), "text", "(2)_get_type()";
is get_name($s), "foo",  "(2)_get_name()";
is get_id  ($s), "baz",  "(2)_get_id()";
is get_value($s),"bar",  "(2)_get_value()";

$s =~ s/\s+/\n/g;

is get_type($s), "text", "(3)_get_type()";
is get_name($s), "foo",  "(3)_get_name()";
is get_id  ($s), "baz",  "(3)_get_id()";
is get_value($s),"bar",  "(3)_get_value()";

$s = q{<INPUT TYPE="text" NAME="foo" VALUE="bar" ID=baz"/>};

is get_type($s), "text", "(4)_get_type()";
is get_name($s), "foo",  "(4)_get_name()";
is get_id  ($s), "baz",  "(4)_get_id()";
is get_value($s),"bar",  "(4)_get_value()";

$s = q{<input type=text name=foo value=bar id=baz />};

is get_type($s), "text", "(5)_get_type()";
is get_name($s), "foo",  "(5)_get_name()";
is get_id  ($s), "baz",  "(5)_get_id()";
is get_value($s),"bar",  "(5)_get_value()";

$s = q{<input value="&lt;&gt;" />};

is get_value($s), '&lt;&gt;', "get raw data";


is_deeply extract($s)->{input}, [$s], "tokenize <input>";
is_deeply extract("blah blah $s blah blah")->{input}, [$s];

is_deeply extract("<input name='foo'>\n<input name='foo'/>\n\t<input name='foo' />")->{input},
	["<input name='foo'>", "<input name='foo'/>", "<input name='foo' />"];

my $s2 = qq{<select name='foo'>\n\n<option>bar</option>\n\n</select>};
is_deeply extract("\n\n$s2\n\n")->{select}, [$s2], "tokenize <select>";

my $s3 = qq{<textarea name='foo'>\n\nbar\n\n</textarea>};
is_deeply extract("\n\n$s3\n\n")->{textarea}, [$s3], "tokenize <textarea>";


is_deeply extract("$s $s $s2 $s2 $s3 $s3"),
	{
		input    => [$s,  $s],
		select   => [$s2, $s2],
		textarea => [$s3, $s3],
	}, "tokenize all";

is_deeply extract(q{<input>})->{input}, [], "ignore no attribute";
is_deeply extract(q{<input type="text"})->{input}, [], "ignore syntax errors";
is_deeply extract(q{<select name="foo">})->{select}, [], "ignore open <select> tag only";
is_deeply extract(q{<textarea name="foo"></textare>})->{textarea}, [], "ignore typo";
