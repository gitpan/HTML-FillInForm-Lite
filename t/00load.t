#!perl

use strict;
use warnings;
use Test::More tests => 4;


use_ok('HTML::FillInForm::Lite');

ok HTML::FillInForm::Lite->can('new'), "can 'new'";

my $o = HTML::FillInForm::Lite->new();

ok ref($o), "new() is ok";
isa_ok $o, 'HTML::FillInForm::Lite';
