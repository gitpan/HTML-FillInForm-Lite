#!perl
use strict;
use warnings;

use HTML::FillInForm::Lite;

my $fif = new HTML::FillInForm::Lite;

my $html = <<'EOD';
<input type="checkbox" name="hoge" value="on" />
<input type="hidden"   name="hoge" value="off" />
EOD

print $fif->fill(\$html, {
	hoge => 'on',
});
