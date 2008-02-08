#!perl

use strict;
use warnings;

use FindBin qw($Bin);
use Fatal qw(open close);

use Test::More tests => 72;

BEGIN{ use_ok('HTML::FillInForm::Lite') }

my $t = "$Bin/test.html";

my %q = (
	foo => 'bar',

	a => ['A', 'B', 'C'],

	s => 'A',

	b => q{"bar"},
	c => q{<bar>},
	d => q{'bar'},
);

my $x     = qr{value="bar"};
my $x_s   = qr{value="A"};
my $x_b   = qr{value="&quot;bar&quot;"};
my $x_c   = qr{value="&lt;bar&gt;"};
my $x_d   = qr{value="'bar'"};

my $unchanged = qr{value="null"};
my $empty     = qr{value=""};

my $checked  = qr{checked="checked"};
my $selected = qr{selected="selected"};

sub my_param{
	my($key) = @_;
	return $q{$key};
}

use CGI;
my $q = CGI->new(\%q);


my $s = q{<input name="foo" value="null" />};

my $o = HTML::FillInForm::Lite->new();

like $o->fill(\$s,  $q),  $x, "fill in scalar ref";
like $o->fill([$s], $q),  $x, "in array ref";
like $o->fill($t, $q), $x, "in file";

like $o->fill(do{ open my($fh), $t or die $!;  *$fh     }, $q), $x, "in filehandle";
like $o->fill(do{ open my($fh), $t or die $!; \*$fh     }, $q), $x, "in filehandle ref";
like $o->fill(do{ open my($fh), $t or die $!;  *$fh{IO} }, $q), $x, "in IO object";

use Tie::Handle;

like $o->fill(do{
	local *FH;
	tie *FH, 'Tie::StdHandle', $t or die $!;
	*FH;
}, $q), $x, "in tied filehandle";

like $o->fill(\$s,  \%q),        $x, "with hash";
like $o->fill(\$s, [\%q]),       $x, "with array";
like $o->fill(\$s, [ {}, \%q ]), $x, "with array";
like $o->fill(\$s, \&my_param),  $x, "with subroutine";

like(HTML::FillInForm::Lite->fill(\$s, \%q), $x, "fill() as class methods");

like $o->fill(\$s, { foo => undef }),
	     $unchanged, "nothing with undef data";

like $o->fill(\$s, { foo => ''}), $empty, "clear data";

like $o->fill(\ q{<input type="text" name="foo" />}, $q), $x, "add value attribute";

my $y = q{<input type="hidden" name="foo" value="baz" />};
like $o->fill(\$y, $q), $x, "hidden";
like $o->fill(\$y, $q), qr/type="hidden"/, "remains a hidden";

$y = q{<input type="submit" name="foo" value="null" />};
is $o->fill(\$y, $q), $y, "ignore submit by default";

$y = q{<input type="reset" name="foo" value="xxx" />};
is $o->fill(\$y, $q), $y, "ignore reset by default";

$y = q{<input type="text" value="" />};
is $o->fill(\$y, $q), $y, "ignore null named";

$y = q{<input type="text" value="" name="" />};
is $o->fill(\$y, $q), $y, "ignore empty name";


# Ignore options

$y = q{<input type="password" name="foo" value="null" />};
like $o->fill(\$y, $q),                     $unchanged, "don't fill in password by default";
like $o->fill(\$y, $q, fill_password => 1), $x,         "fill_password => 1";
like $o->fill(\$y, $q, fill_password => 0), $unchanged, "fill_password => 0";
like $o->fill(\$y, $q),                     $unchanged, "options effects only the call";


like $o->fill(\$s, $q, ignore_types   => ['text']), $unchanged, "ignore_types";
like $o->fill(\$s, $q, ignore_fields  => ['foo']),  $unchanged, "ignore_fields";
like $o->fill(\$s, $q, disable_fields => ['foo']),  $unchanged, "disable_fields";


# new/fill with options

like(HTML::FillInForm::Lite->fill(\$s, $q, ignore_types => ['text']),
	$unchanged, "ignore_types with class method fill()");

like(HTML::FillInForm::Lite->new(ignore_types => ['text'])->fill(\$s, $q),
	$unchanged, "new() with ignroe_types");

like(HTML::FillInForm::Lite->new(ignore_types => [])->fill(\$s, $q, ignore_types => ['text']),
	$unchanged, "new() and fill() with ignroe_types");


like(HTML::FillInForm::Lite->new(ignore_fields => ['foo'])
		->fill(\$s, $q, ignore_fields => []),
		$unchanged, "new() and fill() with ignore_fields");


like(HTML::FillInForm::Lite->new(ignore_fields => [])
		->fill(\$s, $q, ignore_fields => ['foo']),
		$unchanged, "new() and fill() with ignore_fields");

like $o->fill(\ q{<input type="checkbox" name="foo" value="bar" />}, $q),
	      $checked, "checkbox on";
like $o->fill(\ q{<input type="checkbox" name="foo" value="bar" checked="checked" />}, $q),
	      $checked, "checkbox on";
like $o->fill(\ q{<input type="checkbox" name="foo" value="bar" checked='checked'/>}, $q),
	      qr/checked/, "checkbox on";



unlike $o->fill(\ q{<input type="checkbox" name="foo" value="xxx" checked="checked" />}, $q),
	      $checked, "checkbox off";
unlike $o->fill(\ q{<input type="checkbox" name="foo" value="xxx" checked='checked' />}, $q),
	      $checked, "checkbox off";
	      
unlike $o->fill(\ q{<input type="checkbox" name="foo" value="xxx" />}, $q),
	      $checked, "checkbox off";

# multiple values

like $o->fill(\ q{<input name="a" value="A" type="checkbox" />}, $q),
	$checked, "on (multiple values)";

like $o->fill(\ q{<input name="a" type="checkbox" value="B" checked="checked" />}, $q),
	$checked, "on (multiple values)";

unlike $o->fill(\ q{<input type="checkbox" name="a" value="Z" checked="checked" />}, $q),
	$checked, "off (multiple values)";

unlike $o->fill(\ q{<input type="checkbox" value="a" />}, $q),
	$checked, "ignore undefined name";

unlike $o->fill(\ q{<input type="checkbox" name="a" />}, $q),
	$checked, "ignore undefined value";


# radio

like $o->fill(\ q{<input type="radio" name="s" value="A" />}, $q),
	$selected, "select radio button";
unlike $o->fill(\ q{<input type="radio" name="s" value="B" selected="selected" />}, $q),
	$selected, "unselect radio button";
like $o->fill(\ q{<input type="radio" name="s" value="A" selected="selected" />}, $q),
	$selected, "remains selected";
unlike $o->fill(\ q{<input type="radio" name="s" value="B" />}, $q),
	$selected, "remains unselected";

unlike $o->fill(\ q{<input type="radio" name="s" value="Z" selected='selected'/>}, $q),
	qr/selected/, "unselected";
unlike $o->fill(\ q{<input type="radio" name="s" value="Z" selected=selected/>}, $q),
	qr/selected/, "unselected";

unlike $o->fill(\ q{<input type="radio" value="A" />}, $q),
	$selected, "ignore undefined name";
unlike $o->fill(\ q{<input type="radio" name="s" />}, $q),
	$selected, "ignore undefined value";


like $o->fill(\ q{<input type="text" value="" name="b" />}, $q),
	$x_b, "HTML escape";
like $o->fill(\ q{<input type="text" value="" name="c" />}, $q),
	$x_c, "HTML escape";


# Legacy HTML tests

$s = q{<INPUT name="foo" />};
like $o->fill(\$s, $q),$x , "Legacy HTML (capital tagname)";

$s = q{<input NAME="foo" />};
like $o->fill(\$s, $q),$x , "Legacy HTML (capital attrname)";

$s = q{<input name="foo">};
like $o->fill(\$s, $q), $x, "Legacy HTML (unclosed input tag)";

$s = q{<input name=foo />};
like $o->fill(\$s, $q), $x, "Legacy HTML (unquoted attr)";

$s = q{<input name=foo>};
like $o->fill(\$s, $q), $x, "Legacy HTML (unclosed input tag and unquoted attr)";

$s = q{<input name=foo/>};
like $o->fill(\$s, $q), $x, "Invalid HTML (closed input tag and unquoted attr)";


$s = q{<INPUT NAME=foo>};
like $o->fill(\$s, $q), $x, "Legacy HTML (capital tag and unclosed, unquoted, capital attr)";


# Invalid tags

$y = q{<a name="foo" value="" />};
is $o->fill(\$y, $q), $y, "no inputable";

$y = q{<input name="foo"value="" />};
is $o->fill(\$y, $q), $y, "no space between attributes";

# no HTML

$y = q{name="foo" value="null"};
is $o->fill(\$y, $q), $y, "no HTML";

eval{
	$o->fill();
};
ok $@, "Error: no source suplied";

eval{
	$o->fill('foo', undef);
};

ok $@, "Error: no data suplied";

eval{
	$o->fill('no_such_file', $q);
};
ok $@, "Error: cannot open file";

eval{
	$o->fill({}, \$s);
};
ok $@, "Error: bad arguments";

eval{
	$o->fill(\$s, \$s);
};
ok $@, "Error: cannot use scalar ref as query";

eval{
	$o->fill(\$s, bless {}, "the class that hase no param() method");
};
ok $@, "Error: cannot use the object as query";

eval{
	$o->fill(\$s, "foo");
};
ok $@, "Error: cannot use scalar as query";
