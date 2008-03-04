package HTML::FillInForm::Lite::Compat;

use strict;
use warnings;

our $VERSION = '1.00';

use HTML::FillInForm::Lite;
our @ISA = qw(HTML::FillInForm::Lite);

$INC{'HTML/FillInForm.pm'} ||= __FILE__;
push @HTML::FillInForm::ISA, __PACKAGE__
	unless HTML::FillInForm->isa(__PACKAGE__);

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
	escape		=> 1,
	decode_entity	=> 1,
);


BEGIN{
	*fill_file      = \&fill;
	*fill_arrayref  = \&fill;
	*fill_scalarref = \&fill;
}

sub fill{
	my $self = shift;

	my $source;
	my $data;

	if (defined $_[0] and not $known_keys{ $_[0] }) {
		$source = shift;
	}

	if (defined $_[0] and not $known_keys{ $_[0] }) {
		$data = shift;
	}

	my %option = @_;

	$source ||= $option{file} || $option{scalarref} || $option{arrayref};
	$data   ||= $option{fdat} || $option{fobject};

	# ensure to delete all sources and data
	delete @option{qw(scalarref arrayref file fdat fobject)};

	$option{fill_password} = 1
		unless defined $option{fill_password};
	$option{decode_entity} = 1
		unless defined $option{decode_entity};

	$option{ignore_fields} = [ $option{ignore_fields} ]
		if defined $option{ignore_fields}
		   and ref $option{ignore_fields} ne 'ARRAY';

	return $self->SUPER::fill($source, $data, %option);
}

1;

__END__

=encoding UTF-8

=head1 NAME

HTML::FillInForm::Lite::Compat - HTML::FillInForm compatibility layer

=head1 SYNOPSIS

	use HTML::FillInForm::Lite::Compat;

	use HTML::FillInForm; # doesn't require HTML::FillInForm

	my $fif = HTML::FillInForm->new();
	$fif->isa('HTML::FillInForm::Lite'); # => yes

	# or

	perl -MHTML::FillInForm::Lite::Compat script_using_fillinform.pl

=head1 DESCRIPTION

This module provides an interface compatible with C<HTML::FillInForm>.

It B<takes over> the C<use HTML::FillInForm> directive to use
C<HTML::FillInForm::Lite> instead, so that scripts and modules
that depend on C<HTML::FillInForm> go without it.

=head1 SEE ALSO

L<HTML::FillInForm::Lite>.

=head1 AUTHOR

Goro Fuji (藤 吾郎) E<lt>gfuji(at)cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2008 Goro Fuji, Some rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
