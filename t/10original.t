#!perl

# tests from the original HTML::FillInForm distribution

use strict;
use warnings;

use Test::More tests => 4;

use HTML::FillInForm::Lite;

use CGI;


# select.t
# Since processing <select> tags is complex, it is translated for this module

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
my $q = new CGI( { foo1 => '0',
           foo2 => ['bar1', 'bar2',],
	   foo3 => '' }
	);

my $output = HTML::FillInForm::Lite->fill(\$hidden_form_in, $q);

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

my $fif = new HTML::FillInForm::Lite;
$output = $fif->fill(\$hidden_form_in, $q);

$is_selected = join(" ",map { m/selected/ ? "yes" : "no" } grep /option/, split ("\n",$output));

is $is_selected, "yes no no yes yes no no no no no yes no",
	"select test 2";

# test empty option tag

$hidden_form_in = qq{<select name="x"><option></option></select>};
$fif = new HTML::FillInForm::Lite;
$output = $fif->fill(\$hidden_form_in, $q);

is $output, $hidden_form_in, "select test 3 with empty option";

$hidden_form_in = qq{<select name="foo1"><option></option><option value="bar1"></option></select>};
$fif = new HTML::FillInForm::Lite;
$output = $fif->fill(\$hidden_form_in, $q);
like $output, qr/( selected="selected"| value="bar1"){2}/,
	"select test 3 with empty option";


