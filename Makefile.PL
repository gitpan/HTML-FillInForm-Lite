use 5.008_001;
use inc::Module::Install;

name 'HTML-FillInForm-Lite';

all_from 'lib/HTML/FillInForm/Lite.pm';

recommends 'HTML::Entities' => 1.0;

no_index directory => 'example';

WriteAll;
