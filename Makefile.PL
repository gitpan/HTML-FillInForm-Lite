#!perl

use 5.006_00;
use ExtUtils::MakeMaker;

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
