#!perl
# Compatibility tests

use strict;
use warnings;
use Test::More tests => 42;

use HTML::FillInForm::Lite::Compat;

BEGIN{ use_ok('HTML::FillInForm') }

use CGI;
use FindBin qw($Bin);

my $o = HTML::FillInForm->new();

isa_ok $o, 'HTML::FillInForm::Lite';

my $file = "$Bin/test.html";
my $s    = do{ open my($in), '<', $file or die $!; local $/; <$in> };

my %q = (foo => 'bar');
my $q = CGI->new(\%q);

eval{
	HTML::FillInForm->fill();
};

ok $@, "fill without args";

my $output  = HTML::FillInForm->fill(\$s, \%q);

like $output, qr/value="bar"/, "simple fill()";

is $o->fill(scalarref => \$s,   fdat => \%q),  $output, "fill(scalarref, fdat)";
is $o->fill(arrayref  => [$s],  fobject =>  $q),  $output, "fill(arrayref,  fobj)";
is $o->fill(file      => $file, fobject => [$q]), $output, "fill(file, [fobj])";

is $o->fill_scalarref(\$s, fdat => \%q), $output, "fill_scalarref()";
is $o->fill_arrayref([$s], fdat => \%q), $output, "fill_arrayref()";
is $o->fill_file($file, fdat => \%q), $output, "fill_file()";

like $o->fill(\'<input type="password" name="foo">', {foo => 'bar'}),
	qr/value="bar"/, "fill password by default";
unlike $o->fill(\'<input type="password" name="foo">', {foo => 'bar'}, fill_password => 0),
	qr/value="bar"/, "fill_password => 0";


like $o->fill(\<<'EOT', { foo => '<bar>' }), qr/checked/, "decode entities by default";
<input type="radio" value="&#60;bar&#62;" name="foo" />
EOT

unlike $o->fill(\<<'EOT', { foo => '<bar>' }, decode_entity => 0), qr/checked/, "decode_entity => 0";
<input type="radio" value="&#60;bar&#62;" name="foo" />
EOT

SKIP:{
	skip "require HTML::FillInForm::ForceUTF8", 2
		unless eval{ require HTML::FillInForm::ForceUTF8; };
	skip "require &utf8::is_utf8"
		unless defined &utf8::is_utf8;

	my $o = HTML::FillInForm::ForceUTF8->new();

	isa_ok $o, 'HTML::FillInForm::Lite', "HTML::FillInForm::ForceUTF8";

	ok utf8::is_utf8( $o->fill(
		scalarref => \'<input name="foo">',
		fdat      => { foo => 'bar' }) ),
		"extented _get_param()";
}

#==================================================================
# tests from original HTML::FillInForm distribution/t/04_extra.t
#==================================================================

my $hidden_form_in = qq{<select multiple="multiple"  name="foo1">
	<option value="0">bar1</option>
	<option value="bar2">bar2</option>
	<option value="bar3">bar3</option>
</select>
<select multiple="multiple"  name="foo2">
	<option value="bar1">bar1</option>
	<option value="bar2">bar2</option>
	<option value="bar3">bar3</option>
</select>
<select multiple="multiple"  name="foo3">
	<option value="bar1">bar1</option>
	<option selected="selected" value="bar2">bar2</option>
	<option value="bar3">bar3</option>
</select>
<select multiple="multiple"  name="foo4">
	<option value="bar1">bar1</option>
	<option selected="selected" value="bar2">bar2</option>
	<option value="bar3">bar3</option>
</select>};

$q = new CGI( { foo1 => '0',
           foo2 => ['bar1', 'bar2',],
	   foo3 => '' }
	);

$output = HTML::FillInForm->fill(\$hidden_form_in, $q);

my $is_selected = join(" ",map { m/selected/ ? "yes" : "no" } grep /option/, split ("\n",$output));

is $is_selected, "yes no no yes yes no no no no no yes no",
	"select test 1 from the HTML::FillInForm distribution";

$hidden_form_in = qq{<select multiple="multiple"  name="foo1">
	<option>bar1</option>
	<option>bar2</option>
	<option>bar3</option>
</select>
<select multiple="multiple"  name="foo2">
	<option> bar1</option>
	<option> bar2</option>
	<option>bar3</option>
</select>
<select multiple="multiple"  name="foo3">
	<option>bar1</option>
	<option selected="selected">bar2</option>
	<option>bar3</option>
</select>
<select multiple="multiple"  name="foo4">
	<option>bar1</option>
	<option selected="selected">bar2</option>
	<option>bar3  </option>
</select>};

$q = new CGI( { foo1 => 'bar1',
           foo2 => ['bar1', 'bar2',],
	   foo3 => '' }
	);

my $fif = new HTML::FillInForm;
$output = $fif->fill(\$hidden_form_in, $q);

$is_selected = join(" ",map { m/selected/ ? "yes" : "no" } grep /option/, split ("\n",$output));

is $is_selected, "yes no no yes yes no no no no no yes no",
	"select test 2";

# test empty option tag

$hidden_form_in = qq{<select name="x"><option></option></select>};
$fif = new HTML::FillInForm;
$output = $fif->fill(\$hidden_form_in, $q);

is $output, $hidden_form_in, "select test 3 with empty option";

$hidden_form_in = qq{<select name="foo1"><option></option><option value="bar1"></option></select>};
$fif = new HTML::FillInForm;
$output = $fif->fill(\$hidden_form_in, $q);
like $output, qr/( selected="selected"| value="bar1"){2}/,
	"select test 3 with empty option";



#==================================================================
# tests from original HTML::FillInForm distribution/t/19_extra.t
#==================================================================

my $html = qq[
<form>
<input type="text" name="one" value="not disturbed">
<input type="text" name="two" value="not disturbed">
<input type="text" name="three" value="not disturbed">
</form>
];

my $result = HTML::FillInForm->new->fill_scalarref(
                                         \$html,
                                         fdat => {
                                           two => "new val 2",
                                           three => "new val 3",
                                         },
                                         ignore_fields => 'one',
                                         );
my %fdat;

like($result, qr/(?:not disturbed.+one|one.+not disturbed)/,'scalar value of ignore_fields');
like($result, qr/(?:new val 2.+two|two.+new val 2)/,'fill_scalarref worked');
like($result, qr/(?:new val 3.+three|three.+new val 3)/,'fill_scalarref worked 2');


$html = qq[
<form>
<input type="text" name="one" value="not disturbed">
<input type="text" name="two" value="not disturbed">
</form>
];

my @html_array = split /\n/, $html;


{ 
    $result = HTML::FillInForm->new->fill_arrayref(
                                             \@html_array,
                                             fdat => {
                                               one => "new val 1",
                                               two => "new val 2",
                                             },
                                             );

    like($result, qr/(?:new val 1.+one|one.+new val 1)/, 'fill_arrayref 1');
    like($result, qr/(?:new val 2.+two|two.+new val 2)/, 'fill_arrayref 2');
}

{
    $result = HTML::FillInForm->fill(
        \@html_array,
        {
            one => "new val 1",
            two => "new val 2",
        },
     );

    like($result, qr/(?:new val 1.+one|one.+new val 1)/, 'fill_arrayref 1');
    like($result, qr/(?:new val 2.+two|two.+new val 2)/, 'fill_arrayref 2');
}



$html = qq[
<form>
<input type="text" name="one" value="not disturbed">
<input type="text" name="two" value="not disturbed">
</form>
];


$html = qq{<INPUT TYPE="password" NAME="foo1">
};

%fdat = (foo1 => ['bar2', 'bar3']);

$result = HTML::FillInForm->new->fill(scalarref => \$html,
                        fdat => \%fdat);

like($result, qr/(?:bar2.+foo1|foo1.+bar2)/,'first array element taken for password fields');


$html = qq{<TEXTAREA></TEXTAREA>};

%fdat = (area => 'foo1');

$result = HTML::FillInForm->new->fill(scalarref => \$html,
                        fdat => \%fdat);

ok($result !~ /foo1/,'textarea with no name');


$html = qq{<TEXTAREA NAME="foo1"></TEXTAREA>};

%fdat = (foo1 => ['bar2', 'bar3']);

$result = HTML::FillInForm->new->fill(scalarref => \$html,
                        fdat => \%fdat);


ok($result eq '<TEXTAREA NAME="foo1">bar2</TEXTAREA>','first array element taken for textareas');



$html = qq[<div></div>
<!--Comment 1-->
<form>
<!--Comment 2-->
<input type="text" name="foo0" value="not disturbed">
<!--Comment

3-->
<TEXTAREA NAME="foo1"></TEXTAREA>
</form>
<!--Comment 4-->
];

%fdat = (foo0 => 'bar1', foo1 => 'bar2');

$result = HTML::FillInForm->new->fill(scalarref => \$html,
                        fdat => \%fdat);
like($result, qr/(?:bar1.+foo0|foo0.+bar1)/,'form with comments 1');
like($result, qr'<TEXTAREA NAME="foo1">bar2</TEXTAREA>','form with comments 2');
like($result, qr'<!--Comment 1-->','Comment 1');
like($result, qr'<!--Comment 2-->','Comment 2');
like($result, qr'<!--Comment\n\n3-->','Comment 3');
like($result, qr'<!--Comment 4-->','Comment 4');

$html = qq[<div></div>
<? HTML processing instructions 1 ?>
<form>
<? XML processing instructions 2?>
<input type="text" name="foo0" value="not disturbed">
<? HTML processing instructions

3><TEXTAREA NAME="foo1"></TEXTAREA>
</form>
<?HTML processing instructions 4 >
];

%fdat = (foo0 => 'bar1', foo1 => 'bar2');

$result = HTML::FillInForm->new->fill(scalarref => \$html,
                        fdat => \%fdat);

like($result, qr/(?:bar1.+foo0|foo0.+bar1)/,'form with processing 1');
like($result, qr'<TEXTAREA NAME="foo1">bar2</TEXTAREA>','form with processing 2');
like($result, qr'<\? HTML processing instructions 1 \?>','processing 1');
like($result, qr'<\? XML processing instructions 2\?>','processing 2');
like($result, qr'<\? HTML processing instructions\n\n3>','processing 3');
like($result, qr'<\?HTML processing instructions 4 >','processing 4');

#END
