package HTML::FillInForm::Lite::Compat;

use strict;
use warnings;

our $VERSION = '0.02';

use HTML::FillInForm::Lite;
our @ISA = qw(HTML::FillInForm::Lite);

sub import{
	shift;
	if(grep { $_ eq '-takeover' } @_){
		$INC{'HTML/FillInForm.pm'} ||= __FILE__;
		push @HTML::FillInForm::ISA, __PACKAGE__
			unless HTML::FillInForm->isa(__PACKAGE__);
	}
}

sub fill_file		{ my $self = shift; return $self->fill(@_); }
sub fill_arrayref	{ my $self = shift; return $self->fill(@_); }
sub fill_scalarref	{ my $self = shift; return $self->fill(@_); }

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

	if(not $known_keys{ $_[0] || '' }) {
		$source = shift;
	}

	if (not $known_keys{ $_[0] || ''}) {
		$data = shift;
	}

	my %option = @_;

	$source ||= $option{scalarref} || $option{arrayref} || $option{file};
	$data   ||= $option{fdat} || $option{fobject};

	# ensure to delete all sources and data
	delete @option{qw(scalarref arrayref file fdat fobject)};

	$option{fill_password} = 1 unless defined $option{fill_password};

	return $self->SUPER::fill($source, $data, %option);
}

1;

__END__

=head1 NAME

HTML::FillInForm::Lite::Compat - Provides compatibility with HTML::FillInForm

=head1 SYNOPSIS

	perl -MHTML::FillInForm::Lite::Compat=-takeover foo.pl

=head1 DESCRIPTION

This module provides the compatible interface with C<HTML::FillInForm>.

And with C<-takeover> option, it replaces C<HTML::FillInForm> by
C<HTML::FillInForm::Lite> so that scripts and modules that depend on
C<HTML::FillInForm> go without it.

See L<HTML::FillInForm::Lite> and L<HTML::FillInForm> for details.

=begin comment

Firstly, this wapper module was intended to test compatibility with
C<HTML::FillInForm>. However, the plan was failed, because the tests in
the C<HTML::FillInForm> distribution is too specific to be passed through by
C<HTML::FillInForm::Lite>.

=end comment

=cut
