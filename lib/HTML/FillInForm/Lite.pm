package HTML::FillInForm::Lite;

require 5.006_00;

use strict;
use warnings;
use Carp qw(croak);

#use Smart::Comments '####';

our $VERSION  = '0.06';

# Regexp for HTML tags

my $SPACE       =  q{\s};
my $IDENT       =  q{[a-zA-Z]+};
my $ATTR_VALUE  =  q{(?: " [^"]* " | ' [^']* ' | [^'">/\s]+ )};
my $ATTR        = qq{(?:$SPACE+ $IDENT = $ATTR_VALUE )};

my $FORM     = qq{(?: <form     $ATTR+ $SPACE*>  )};
my $INPUT    = qq{(?: <input    $ATTR+ $SPACE*/?>)};
my $SELECT   = qq{(?: <select   $ATTR+ $SPACE* > )};
my $OPTION   = qq{(?: <option   $ATTR* $SPACE* > )};
my $TEXTAREA = qq{(?: <textarea $ATTR+ $SPACE* > )};

my $END_FORM     = q{(?: </form>     )};
my $END_SELECT   = q{(?: </select>   )};
my $END_OPTION   = q{(?: </option>   )};
my $END_TEXTAREA = q{(?: </textarea> )};

my $CHECKED  = q{(?: checked  = (?: "checked " | 'checked'  | checked  ) )};
my $SELECTED = q{(?: selected = (?: "selected" | 'selected' | selected ) )};
#my $DISABLED = q{(?: disabled = (?: "disabled" | 'disabled' | disabled ) )};

#sub _extract{ # for debugging only
#	my $s = shift;
#	my %f = (input => [], select => [], textarea => []);
#	@{$f{input}}    = $s =~ m{($INPUT)}ogxmsi;
#	@{$f{select}}   = $s =~ m{($SELECT.*?$END_SELECT)}ogxmsi;
#	@{$f{textarea}} = $s =~ m{($TEXTAREA.*?$END_TEXTAREA)}ogxmsi;
#
#	return \%f;
#}

sub new{
	my $class = shift;

	my $option = $class->_parse_option(@_);
	return bless $option => $class;
}

sub _parse_option{
	my $self = shift;

	if(ref $self and not @_){ # HTML::FillInForm::Lite->new(...)->fill(...)
		return $self;
	}

	my %option = (
		ignore_type => {
			button   => 1,
			submit   => 1,
			reset    => 1,
			password => 1,
		},
		target      => undef,

		escape      => \&_escapeHTML,
	);

	# merge
	foreach my $key( ref($self) ? keys %{$self} : () ){
		my $val = $self->{$key};

		if(ref($val) eq 'HASH'){
			@{ $option{$key} }{ keys %{$val} }
				= values %{$val};
		}
		else{
			$option{$key} = $val;
		}
	}

	while(my($opt, $val) = splice @_, 0, 2){
		next unless defined $val;

		if(	   $opt eq 'ignore_types'
			or $opt eq 'ignore_fields'
			or $opt eq 'disable_fields'
		){

			chop $opt; # plural to singular
			@{ $option{$opt} ||= {} }{ @{$val} }
				= (1) x @{$val};
		}
		elsif($opt eq 'fill_password'){
			$option{ignore_type}{password} = !$val;
		}
		elsif($opt eq 'target'){
			$option{target} = $val;
		}
		elsif($opt eq 'escape'){
			if($val){
				$option{escape} = ref($val) eq 'CODE'
					? $val
					: \&_escapeHTML
			}
			else{
				$option{escape} = \&_noop;
			}
		}
		else{
			croak("Unknown option '$opt' suplied");
		}
	}

	return \%option;
}

sub fill{
	my($self, $src, $q, @opt) = @_;

	if (not defined $src){
		croak('No source suplied');
	}
	if (not defined $q){
		croak('No data suplied');
	}

	my $option = $self->_parse_option(@opt);

	### $option


	# HTML source to a scalar
	my $content;
	if(ref($src) eq 'SCALAR'){
		$content = ${$src};
	}
	elsif(ref($src) eq 'ARRAY'){
		$content = join q{}, @{$src};
	}
	else{
		if(not defined fileno $src){
			open my($in), '<', $src
				or croak("Cannot open '$src': $!");
			$src = $in;
		}
		$content = do{ local $/ = undef; <$src> };
	}

	# Form data to an object
	local $option->{data} =  _to_form_object($q);

	# It's just a cache. It's needed to implement multi-text fields
	local $option->{param_cache} = {};

	# Fill in contents
	if(defined $option->{target}){

		$content =~ s{ ($FORM) (.*?) ($END_FORM) }
		             {	my($form, $content, $end_form) = ($1, $2, $3);

				my $id = _get_id($form);
				(defined($id) and $option->{target} eq $id)
					? $form . _fill($option, $content) . $end_form
					: $form . $content . $end_form
			     }goexmsi;
		return $content;
	}
	else{
		return _fill($option, $content);
	}

}

sub _fill{
	my($option, $content) = @_;
	$content =~ s{($INPUT)}{ _fill_input($option, $1)        }goexmsi;

	$content =~ s{($SELECT) (.*?) ($END_SELECT) }
		     { $1 . _fill_select($option, $1, $2) . $3   }goexmsi;

	$content =~ s{($TEXTAREA) (.*?) ($END_TEXTAREA) }
		     { $1 . _fill_textarea($option, $1, $2) . $3 }goexmsi;

	return $content;
}

sub _get_param{
	my($option, $name, $type) = @_;

	return if !defined($name)
		or $option->{ignore_type} {$type}
		or $option->{ignore_field}{$name};

	my $ref = $option->{param_cache}{$name} ||= [ $option->{data}->param($name) ];

	return @{$ref} ? $ref : undef;
}

sub _fill_input{
	my($option, $tag) = @_;

	### $tag

	my $type  = _get_type($tag) || 'text';
	my $name  = _get_name($tag);

	my $values_ref = _get_param($option, $name, $type)
		or return $tag;

#	_disable($option, $name, $tag);

	if($type eq 'checkbox' or $type eq 'radio'){
		my $value = _get_value($tag);

		if(not defined $value){
			$value = 'on';
		}
		if(grep{ $_ eq $value } @{$values_ref}){
			$tag =~ /$CHECKED/oxmsi
				or $tag =~ s{\s* /? > $}
					    { checked="checked" />}xms;
		}
		else{
			$tag =~ s/\s+$CHECKED//goxmsi;
		}
	}
	else{
		my $new_value = $option->{escape}->(shift @{$values_ref});

		$tag =~ s{value = $ATTR_VALUE}{value="$new_value"}oxmsi
			or $tag =~ s{\s* /? > $}
				    { value="$new_value" />}xms;
	}
	return $tag;
}
sub _fill_select{
	my($option, $tag, $content) = @_;

	my $name = _get_name($tag);

	my $values_ref = _get_param($option, $name, 'select')
		or return $content;

#	_disable($option, $name, $tag);

	$content =~ s{($OPTION) (.*?) ($END_OPTION)}
		     { _fill_option($values_ref, $1, $2) . $2 . $3 }goexsm;
	return $content;
}
sub _fill_option{
	my($values_ref, $tag, $content) = @_;

	my $value = _get_value($tag);
	unless( defined $value ){
		$value = $content;
		$value =~ s{\A $SPACE+   } {}oxms;
		$value =~ s{   $SPACE{2,}}{ }oxms;
		$value =~ s{   $SPACE+ \z} {}oxms;
	}

	### @_
	if(grep{ $value eq $_ } @{$values_ref}){
		$tag =~ /$SELECTED/oxmsi
			or $tag =~ s{ \s* > $}
				    { selected="selected">}xms;
	}
	else{
		$tag =~ s/\s+$SELECTED//goxmsi;
	}
	return $tag;
}

sub _fill_textarea{
	my($option, $tag, $content) = @_;

	my $name = _get_name($tag);

	my $values_ref = _get_param($option, $name, 'textarea')
		or return $content;


#	_disable($option, $name, $tag);

	return $option->{escape}->(shift @{$values_ref});
}

# utilities

sub _noop{
	return $_[0];
}
sub _escapeHTML{
	my $s = shift;
#	return '' unless defined $s;

	$s =~ s/&/&amp;/g;
	$s =~ s/</&lt;/g;
	$s =~ s/>/&gt;/g;
	$s =~ s/"/&quot;/g;
	return $s;
}
#sub _unescapeHTML
#{
#	my $s = shift;
#	return '' unless defined $s;
#
#	$s =~ s/&amp;/&/g;
#	$s =~ s/&lt;/</g;
#	$s =~ s/&gt;/>/g;
#	$s =~ s/&quot;/"/g;
#	$s =~ s{&#(\d+);}{chr $1}eg;
#	$s =~ s{&#x([0-9a-fA-F]+);}{ chr hex $1}eg;
#	return $s;
#}

sub _unquote{
	$_[0] =~ /(['"]) (.*) \1/xms or return $_[0];
	return $2;
}
sub _get_id{
	$_[0] =~ /id    = ($ATTR_VALUE)/oxmsi or return;
	return _unquote($1);
}
sub _get_type{
	$_[0] =~ /type  = ($ATTR_VALUE)/oxmsi or return;
	return _unquote($1);
}
sub _get_name{
	$_[0] =~ /name  = ($ATTR_VALUE)/oxmsi or return;
	return _unquote($1);
}
sub _get_value{
	$_[0] =~ /value = ($ATTR_VALUE)/oxmsi or return;
	return _unquote($1);
}

#sub _disable{
#	my $option = shift;
#	my $name   = shift;
#
#	if($option->{disable_field}{$name}){
#		$_[0] =~ /$DISABLED/oxmsi
#			or $_[0] =~ s{\s* /? > $}
#				    { disabled="disabled" />}xmsi;
#	}
#	return;
#}

sub _to_form_object{
	my($ref) = @_;

	my $type = ref $ref;

	my $wrapper;
	if($type eq 'HASH'){
		$wrapper = {};
		@{$wrapper}{ keys %{$ref} }
			= map{
				ref($_) eq 'ARRAY' ?  $_  :
				defined($_)        ? [$_] :
						     ();
			     } values %{$ref};
	}
	elsif($type eq 'ARRAY'){
		$wrapper = [];
		@{$wrapper} = map{ _to_form_object($_) } @{$ref};
	}
	elsif($type eq 'CODE'){
		$wrapper = \$ref;
	}
	elsif($type and $type->can('param')){ # e.g. an instance of CGI.pm
		return $ref;
	}
	else{
		croak("Cannot use '$ref' as form data");
	}

	return bless $wrapper => __PACKAGE__ . '::' . $type;
}
sub HTML::FillInForm::Lite::HASH::param{
	my($hash_ref, $key) = @_;

	my $value = $hash_ref->{$key} or return;

	return @{ $value };
}

sub HTML::FillInForm::Lite::ARRAY::param{
	my($ary_ref, $key) = @_;

	return map{ $_->param($key) } @{$ary_ref};
}

sub HTML::FillInForm::Lite::CODE::param{
	my($ref_to_code_ref, $key) = @_;

	return ${$ref_to_code_ref}->($key);
}

1;

__END__

=encoding UTF-8

=head1 NAME

HTML::FillInForm::Lite - Fills in HTML forms with data

=head1 VERSION

The document describes HTML::FillInForm version 0.06

=head1 SYNOPSIS

	use HTML::FillInForm::Lite;
	use CGI;

	my $q = CGI->new();
	my $h = HTML::FillInForm::Lite->new();

	$output = $h->fill(\$html,    $q);
	$output = $h->fill(\@html,    \%data);
	$output = $h->fill(\*HTML,    \&get_param);
	$output = $h->fill('t.html', [$q, \%default]);

	$output = $h->fill(\$html, $q,
		fill_password => 0, # it is default
		ignore_fields => ['foo', 'bar'],
		target        => $form_id,
	);


=head1 DESCRIPTION

This module fills in HTML forms with Perl data,
which re-implements C<HTML::FillInForm> using regexp-based parser,
not using C<HTML::Parser>.

The difference in the parsers makes C<HTML::FillInForm::Lite> about 2
times faster than C<HTML::FillInForm>.

=head1 METHODS

=head2 new(options...)

Creates C<HTML::FillInForm::Lite> processer with I<options>.

There are several options. All the options are disabled when C<undef> is
suplied.

Acceptable options are as follows:

=over 4

=item fill_password => I<bool>

To enable passwords to be filled in, set the option true.

Note that the effect of the option is the same as that of C<HTML::FillInForm>,
but by default C<HTML::FillInForm::Lite> ignores password fields.

=item ignore_fields => I<array_ref_of_fields>

To ignore some fields from filling.

=item target => I<form_id>

To fill in just the form identified by I<form_id>.

=item ignore_type => I<array_ref_of_types>

To ignore some types from filling.

Note that it is not implemented in C<HTML::FillInForm>.

=item escape => I<bool> | I<ref>

If true is provided (or by default), values filled in text fields will be
html-escaped, e.g. C<< <tag> >> to be C<< &lt;tag&gt; >>.

If the values are already html-escaped, set the option false.

If a code reference is provided, it will be used to escape the values.

Note that it is not implemented in C<HTML::FillInForm>.

=back

=head2 fill(source, form_data [, options...])

Fills in I<source> with I<form_data>.

The I<options> are the same as C<new()>'s.

You can use this method as both class or instance method, 
but you make multiple calls to C<fill()> with the same
options, it is a little faster to call C<new()> before C<fill()>.

To clear all the fields, provide I<form_data> with a subroutine returning an
empty string, like:

	HTML::FillInForm::Lite->fill($source, sub{ '' });

I<form_data> as a subroutine is called in list context. That is, to leave
some fields untouched, it must return C<()>, not C<undef>.

=head1 LIMITATIONS

=head2 Compatibility with C<HTML::FillInForm>

This module implements only the new syntax of C<HTML::FillInForm>
version 2.

=head2 Compatibility with legacy HTML

This module is designed to process XHTML 1.x.

And it also supporting a good part of HTML 4.x , but there are some
limitations. First, it doesn't understand html-attributes that the name is
omitted. 

For example:

	<INPUT TYPE=checkbox NAME=foo CHECKED> -- NG.
	<INPUT TYPE=checkbox NAME=foo CHECKED=CHECKED> - OK, but obsolete.
	<input type="checkbox" name="foo" checked="checked" /> - OK, valid XHTML

Then, it always treats the values of attributes case-sensitively.
In the example above, the value of C<type> must be lower-case.

Moreover, it doesn't recognize ommited closing tags, like:

	<select name="foo">
		<option>bar
		<option>baz
	</select>

When you can't get what you want, try to give your source to a HTML lint.

=head2 Comment handling

This module processes all the processible, not knowing comments
nor something that shouldn't be processed.

It may cause problems. Suppose there is a code like:

	<script> document.write("<input name='foo' />") </script>

HTML::FillInForm will process the code to be broken:

	<script> document.write("<input name='foo' value="bar" />") </script>

To avoid such problems, you can use the C<ignore_fields> option.

=head1 BUGS

There are no known bugs.

Bug reports and other feedback are welcome.

=head1 SEE ALSO

L<HTML::FillInForm>.

L<HTML::FillInForm::Lite::JA> - the document in Japanese.

=head1 AUTHOR

Goro Fuji (藤 吾郎) E<lt>gfuji(at)cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2008 Goro Fuji, Some rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

