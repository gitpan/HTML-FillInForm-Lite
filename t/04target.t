#!perl

use strict;
use warnings;
use Test::More tests => 11;

BEGIN{ use_ok('HTML::FillInForm::Lite') }

my $s = <<'HTML';
	<form id="foo">
	<input name="bar" value="null"/>
	</form>
HTML
my $x = <<'HTML';
	<form id="foo">
	<input name="bar" value="ok"/>
	</form>
HTML

is(HTML::FillInForm::Lite->fill(\$s, { bar => "ok" }, target => "foo"),
	$x, "class method fill() with target");

is(HTML::FillInForm::Lite->new(target => 'foo')->fill(\$s, { bar => "ok" }),
	$x, "new() with target");

is(HTML::FillInForm::Lite->fill(\$s, { bar => "ok" }, target => "no_foo"),
	$s, "class method fill() with different target");

is(HTML::FillInForm::Lite->new(target => "no_foo")->fill(\$s, { bar => "ok" }),
	$s, "new() with different target");

is(HTML::FillInForm::Lite->new(target => "no_foo")->fill(\$s, { bar => "ok" }, target => "foo"),
	$x, "target overriding");

is(HTML::FillInForm::Lite->new(target => "foo")->fill(\<<'EOT', { bar => "ok"}), <<'EOT');
<form method="get"><input type="bar" value="null" /></form>
EOT
<form method="get"><input type="bar" value="null" /></form>
EOT

my $o = HTML::FillInForm::Lite->new();

is $o->fill(\$s, { bar => "ok" }, target => "foo"), $x,
	"instance method fill() with target";



is $o->fill(\$s, { bar => "ok" }, target => "no_foo"), $s,
	"different target";

is $o->fill(\q{
	<form id="foo">
	<input name="bar" value="null"/>
	</form>
	<form id="not_foo">
	<input name="bar" value="null"/>
	</form>}, { bar => "ok" }, target => "foo"),

	q{
	<form id="foo">
	<input name="bar" value="ok"/>
	</form>
	<form id="not_foo">
	<input name="bar" value="null"/>
	</form>}, "the target only";

is $o->fill(\q{
	<form id="not_foo">
	<input name="bar" value="null"/>
	</form>
	<form id="foo">
	<input name="bar" value="null"/>
	</form>}, { bar => "ok" }, target => "foo"),

	q{
	<form id="not_foo">
	<input name="bar" value="null"/>
	</form>
	<form id="foo">
	<input name="bar" value="ok"/>
	</form>}, "ignore different target";
