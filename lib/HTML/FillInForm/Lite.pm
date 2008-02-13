package HTML::FillInForm::Lite;

use strict;
use warnings;
use Carp qw(croak);

#use Smart::Comments '####';

our $VERSION  = '0.032';

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

my $ID    = 'id';
my $NAME  = 'name';
my $TYPE  = 'type';
my $VALUE = 'value';


# Fixes the regexp components to match capital names
foreach my $component(
	$FORM, $INPUT, $SELECT, $OPTION, $TEXTAREA,
	$END_FORM, $END_SELECT, $END_OPTION, $END_TEXTAREA,
	$CHECKED, $SELECTED, $ID, $NAME, $TYPE, $VALUE){

	$component =~ s{([a-z]{2,})}
		{ join '', map{ qq/[$_\U$_]/ } split //, $1 }egxms;
	#### $component
}

sub _extract{ # for debugging only
	my $s = shift;
	my %f = (input => [], select => [], textarea => []);
	@{$f{input}}    = $s =~ m{($INPUT)}ogxms;
	@{$f{select}}   = $s =~ m{($SELECT.*?$END_SELECT)}ogxms;
	@{$f{textarea}} = $s =~ m{($TEXTAREA.*?$END_TEXTAREA)}ogxms;

	return \%f;
}

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
		ignore_name => {

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

		if($opt eq 'ignore_types'){
			@{ $option{ignore_type} }{ @{$val} }
				= (1) x @{$val};
		}
		elsif($opt eq 'fill_password'){
			$option{ignore_type}{password} = !$val;
		}
		elsif($opt eq 'ignore_fields' or $opt eq 'disable_fields'){
			@{ $option{ignore_name} }{ @{$val} }
				= (1) x @{$val};
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
				$option{escape} = \&_noop_filter;
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
		croak("No source suplied");
	}
	if (not defined $q){
		croak("No data suplied");
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
	$q = _to_form_object($q);

	# Fill in contents
	if($option->{target}){
		$content =~ s{ ($FORM) (.*?) ($END_FORM) }
		             {	my($form, $content, $end_form) = ($1, $2, $3);

				my $id = _get_id($form);
				(defined($id) and $option->{target} eq $id)
					? $form . _fill($option, $q, $content) . $end_form
					: $form . $content . $end_form
			     }goexms;
		return $content;
	}
	else{
		return _fill($option, $q, $content);
	}

}

sub _fill{
	my($option, $q, $content) = @_;

	$content =~ s{($INPUT)}{ _fill_input($option, $q, $1)        }goexms;

	$content =~ s{($SELECT) (.*?) ($END_SELECT) }
		     { $1 . _fill_select($option, $q, $1, $2) . $3   }goexms;

	$content =~ s{($TEXTAREA) (.*?) ($END_TEXTAREA) }
		     { $1 . _fill_textarea($option, $q, $1, $2) . $3 }goexms;

	return $content;
}

sub _ignore{
	my($option, $type, $name) = @_;

	if(defined $name and length $name){
		return     $option->{ignore_type}{$type}
			|| $option->{ignore_name}{$name};
	}

	return 1; # unnamed fields are ignored
}

sub _fill_input{
	my($option, $q, $tag) = @_;

	### $tag

	my $type  = _get_type($tag) || 'text';
	my $name  = _get_name($tag);

	my @values;
	if(_ignore($option, $type, $name)
		or not (@values = $q->param($name))) {
		return $tag;
	}

	if($type eq 'radio'){
		my $value = _get_value($tag);

		if(not defined $value){
			return $tag;
		}

		if(grep{ $_ eq $value } @values){
			$tag =~ /$SELECTED/oxms
				or $tag =~ s{\s* /? > $}
					    { selected="selected" />}xms;
		}
		else{
			$tag =~ s/\s*$SELECTED//goxms;
		}
	}
	elsif($type eq 'checkbox'){
		my $value = _get_value($tag);

		if(not defined $value){
			return $tag;
		}

		if(grep{ $_ eq $value } @values){
			$tag =~ /$CHECKED/oxms
				or $tag =~ s{\s* /? > $}
					    { checked="checked" />}xms;
		}
		else{
			$tag =~ s/\s*$CHECKED//goxms;
		}
	}
	else{
		my $new_value = $option->{escape}->($values[0]);

		$tag =~ s{$VALUE = $ATTR_VALUE}{value="$new_value"}oxms
				or $tag =~ s{\s* /? > $}
					    { value="$new_value" />}xms;
	}
	return $tag;
}
sub _fill_select{
	my($option, $q, $tag, $content) = @_;

	my $name = _get_name($tag);

	my @values;
	if(_ignore($option, 'select', $name)
		or not (@values = $q->param($name))) {
		return $content;
	}

	my %value;
	@value{@values} = ();

	$content =~ s{($OPTION) (.*?) ($END_OPTION)}
		     { _fill_option($q, \%value, $1, $2) . $2 . $3 }xgoes;
	return $content;
}
sub _fill_option{
	my($q, $value_ref, $tag, $content) = @_;

	my $value = _get_value($tag);
	$value = $content if not defined $value;

	### @_
	if(exists $value_ref->{$value}){
		$tag =~ /$SELECTED/oxms
			or $tag =~ s{ \s* > $}
				    { selected="selected">}xms;
	}
	else{
		$tag =~ s/\s*$SELECTED//goxms;
	}
	return $tag;
}

sub _fill_textarea{
	my($option, $q, $tag, $content) = @_;

	my $name = _get_name($tag);

	my $value;
	if(_ignore($option, 'textarea', $name)
		or not defined($value = $q->param($name))) {
		return $content;
	}

	return $option->{escape}->($value);
}

# utilities

sub _noop_filter{
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
	$_[0] =~ m/ (["']) (.*) \1 /xms or return $_[0];
	return $2;
}

sub _get_id{
	my($value) = $_[0] =~ /$ID=($ATTR_VALUE)/oxms or return;
	return _unquote($value);
}
sub _get_type{
	my($value) = $_[0] =~ /$TYPE=($ATTR_VALUE)/oxms or return;
	return _unquote($value);
}
sub _get_name{
	my($value) = $_[0] =~ /$NAME=($ATTR_VALUE)/oxms or return;
	return _unquote($value);
}
sub _get_value{
	my($value) = $_[0] =~ /$VALUE=($ATTR_VALUE)/oxms or return;
	return _unquote($value);
}


sub _to_form_object{
	my($ref) = @_;

	my $type = ref $ref;

	my $wrapper;
	if($type eq 'HASH'){
		$wrapper = {};
		@{$wrapper}{ keys %{$ref} }
			= map{ [grep{ defined } ref($_) eq 'ARRAY' ? @{$_} : $_] }
				values %{$ref};
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

	return wantarray ? @{ $value } : $value->[0];
}

sub HTML::FillInForm::Lite::ARRAY::param{
	my($ary_ref, $key) = @_;

	if(wantarray){
		return map{ $_->param($key) } @{$ary_ref};
	}
	else{
		return(
			(grep{ defined $_ }
				map{ scalar $_->param($key) } @{$ary_ref})[0]
		);
	}
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

The document describes HTML::FillInForm version 0.032

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
			# or disable_fields => [...]
		target        => $form_id,
	);


=head1 DESCRIPTION

This module fills in HTML forms with Perl data,
which re-implements C<HTML::FillInForm> using regexp-based parser,
not using C<HTML::Parser>.

The difference in the parsers makes C<HTML::FillInForm::Lite> 2 or more
times faster than C<HTML::FillInForm>.

=head1 METHODS

=head2 new(options...)

Creates C<HTML::FillInForm::Lite> processer with I<options>.

There are several options. All the methods are disabled when C<undef> is
suplied.

Acceptable options are as follows:

=over 4

=item fill_password => I<bool>

Unlike C<HTML::FillInForm>, the C<fill()> method ignores
passwords by default.

To enable passwords to be filled in, set the option true. 

=item ignore_fields => I<array_ref_of_fields>

=item disable_fields => I<array_ref_of_fields>

To ignore some fields from filling.

=item target => I<form_id>

To fill in just the form identified by I<form_id>.

=item ignore_type => I<array_ref_of_types>

To ignore some types from filling.

Note that it is not implemented in C<HTML::FillInForm>.

=item escape => I<bool> | I<ref>

If true is provided (or by default), values filled in text fields will be
html-escaped, e.g. C<< <tag> >> to be C<< &lt;tag&gt; >>.

The values are already html-escaped, set the option false.

If a code reference is provided, it will be used to escape the values.

Note that it not implemented in C<HTML::FillInForm>.

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

This is because if returning values are undefined, it will leave the elements
untouched.

=head1 LIMITATIONS

=head2 Compatibility with C<HTML::FillInForm>

This module implements only the new syntax of C<HTML::FillInForm>
version 2.

=head2 Compatibility with legacy HTML

It understands XHTML 1.x, and also supports a good part of HTML 4.x, but there
are some limitations. First, it doesn't understand html-attributes that the
name is omitted. 

For example:

	<INPUT TYPE=checkbox NAME=foo CHECKED> -- NG.
	<INPUT TYPE=checkbox NAME=foo CHECKED=CHECKED> - OK, but obsolete.
	<input type="checkbox" name="foo" checked="checked" /> - OK, valid XHTML

Then, it always treats the values of attributes case-sensitively.
In the example above, the value of C<type> must be lower-case.

=head2 Comment handling

This module processes all the processible, not knowing comments
nor something that shouldn't be processed.

It may cause problems. Suppose there is a code like:

	<script> document.write("<input name='foo' />") </script>

HTML::FillInForm will process the code to be broken:

	<script> document.write("<input name='foo' value="bar" />") </script>

To avoid such problems, you can use the C<ignore_fields> option.

=head1 SEE ALSO

L<HTML::FillInForm>.

=head1 AUTHOR

Goro Fuji (藤 吾郎) E<lt>gfuji(at)cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2008 Goro Fuji, Some rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

