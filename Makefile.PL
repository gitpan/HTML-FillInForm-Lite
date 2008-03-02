#!perl

use 5.006_000;
use ExtUtils::MakeMaker;

if($] == 5.008_000){
	warn <<'EOT';
WARNING:  Perl 5.8.0 is not recommended. If you'd like to use unicode in Perl,
          you should upgrade Perl to 5.8.1 or later.

EOT
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
