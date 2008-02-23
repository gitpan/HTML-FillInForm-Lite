#!perl

use 5.006_000;
use ExtUtils::MakeMaker;

if($] == 5.008_000){
	warn "WARNING:  Perl 5.8.0 is not recommended,",
		"because of lack of utf8::is_utf8()";
}

WriteMakefile(
	NAME		=> 'HTML::FillInForm::Lite',
	VERSION_FROM	=> 'lib/HTML/FillInForm/Lite.pm',
	PREREQ_PM	=> {
		'Test::More' => 0,
	},
	LICENSE		=> 'perl',

	ABSTRACT_FROM	=> 'lib/HTML/FillInForm/Lite.pm',
	AUTHOR		=> 'Goro Fuji',
);
