#!perl
use strict;
use warnings FATAL => 'all';

use Test::More tests => 14;


use HTML::FillInForm::Lite;

my $o = HTML::FillInForm::Lite->new(decode_entity => 1);

ok !(HTML::Entities->VERSION), "HTML::Entities not loaded";

my $s = <<'EOT';
<input type="radio" value="&#60;bar&#62;" name="foo" />
EOT

like $o->fill(\$s, { foo => '<bar>' }), qr/checked/, "radio with HTML entities (numeric)";

$s = <<'EOT';
<input type="radio" value="&#x3c;bar&#x3e;" name="foo" />
EOT

like $o->fill(\$s, { foo => '<bar>' }), qr/checked/, "radio with HTML entities (hex numeric)";


$s = <<'EOT';
<input type="checkbox" value="&#60;bar&#62;" name="foo" />
EOT

like $o->fill(\$s, { foo => '<bar>' }), qr/checked/, "checkbox with HTML entities (numeric)";


$s = <<'EOT';
<select name="foo">
<option value="&#60;bar&#62;">ok</option>
</select>
EOT

like $o->fill(\$s, { foo => '<bar>' }), qr/selected/, "select with value, with HTML entities (numeric)";


$s = <<'EOT';
<select name="foo">
<option>&#60;bar&#62;</option>
</select>
EOT

like $o->fill(\$s, { foo => '<bar>' }), qr/selected/, "select without values, with HTML entities (numeric)";

ok !(HTML::Entities->VERSION), "HTML::Entities remains not loaded";

SKIP:{
	skip "require HTML::Entities", 7
		if not eval{ require HTML::Entities; };
	$s = <<'EOT';
	<input type="radio" value="&lt;bar&gt;" name="foo" />
EOT

	like $o->fill(\$s, { foo => '<bar>' }), qr/checked/, "radio with HTML entities";

	$s = <<'EOT';
	<input type="radio" value="&lt;bar&gt;" name="foo" />
EOT

	like $o->fill(\$s, { foo => '<bar>' }), qr/checked/, "checkbox with HTML entities";

	$s = <<'EOT';
	<select name="foo">
	<option value="&lt;bar&gt;">ok</option>
	</select>
EOT

	like $o->fill(\$s, { foo => '<bar>' }), qr/selected/, "select with value, with HTML entities";

	$s = <<'EOT';
	<select name="foo">
	<option>&lt;bar&gt;</option>
	</select>
EOT

	like $o->fill(\$s, { foo => '<bar>' }), qr/selected/, "select without values, with HTML entities";

	$o = HTML::FillInForm::Lite->new(decode_entity => 0);

	$s = <<'EOT';
	<select name="foo">
	<option>&lt;bar&gt;</option>
	</select>
EOT

	unlike $o->fill(\$s, { foo => '<bar>' }), qr/selected/, "decode_entity => 0";

	like $o->fill(\$s, { foo => '<bar>' }, decode_entity => \&HTML::Entities::decode),
		qr/selected/, "set decode_entity => \\&HTML::Entities::decode";


	ok !!(HTML::Entities->VERSION), "HTML::Entities loaded";

}
