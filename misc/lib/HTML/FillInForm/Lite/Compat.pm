package
	HTML::FillInForm::Lite::Compat;

use strict;
use warnings;
use Carp qw(croak);

our $VERSION = '0.01';

$INC{'HTML/FillInForm.pm'} ||= __FILE__;

use HTML::FillInForm::Lite;
our @ISA = qw(HTML::FillInForm::Lite);

push @HTML::FillInForm::ISA, __PACKAGE__
	unless grep { $_ eq __PACKAGE__ } @HTML::FillInForm::ISA;

# copy from HTML::FillInForm
sub fill_file		{ my $self = shift; return $self->fill('file',     @_); }
sub fill_arrayref	{ my $self = shift; return $self->fill('arrayref' ,@_); }
sub fill_scalarref	{ my $self = shift; return $self->fill('scalarref',@_); }

my %known_keys = (
	scalarref	=> 1,
	arrayref	=> 1,
	fdat		=> 1,
	fobject		=> 1,
	file		=> 1,
	target	 	=> 1,
	fill_password	=> 1,
	ignore_fields	=> 1,
	disable_fields	=> 1,

	# additional options in Lite.pm
	ignore_types	=> 1,
	escape		=> 1,
);

sub fill{
	my $self = shift;

	my $source;
	my $data;

	if(ref $_[0] or not $known_keys{ $_[0] }) {
		$source = shift;
	}

	if (ref $_[0]) {
		$data = shift;
	}

	my %option = @_;

	$source ||= $option{scalarref} || $option{arrayref} || $option{file};
	$data   ||= $option{fdat} || $option{fobject};

	# ensure to delete source and data
	delete @option{qw(scalarref arrayref file fdat fobject)};

	$option{fill_password} ||= 0;

	return $self->SUPER::fill($source, $data, %option);
}

1;

__END__

=head1 NAME

HTML::FillInForm::Lite::Compat - Replaces FillInForm by FillInForm::Lite

=head1 SYNOPSIS

	perl -MHTML::FillInForm::Lite::Compat foo.pl

=head1 DESCRIPTION

Firstly, this wapper module was intended to test compatibility with
C<HTML::FillInForm>. However, the plan was failed, because the tests in
the C<HTML::FillInForm> distribution is too specific to be passed through by
C<HTML::FillInForm::Lite>.

=cut
