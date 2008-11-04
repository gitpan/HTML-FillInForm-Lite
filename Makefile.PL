use 5.008_001;
use strict;
use inc::Module::Install;

name 'HTML-FillInForm-Lite';

all_from 'lib/HTML/FillInForm/Lite.pm';

test_requires 'Test::More' => 0.62;

#build_requires 'macro' => 0.04;
#pmc_support;

WriteMakefile(
	clean => {FILES => 'HTML-FillInForm-Lite-* cover_db'},
);
