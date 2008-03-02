package HTML::FillInForm::Lite;

require 5.006_000;

use strict;
use warnings;
use Carp qw(croak);

#use Smart::Comments '####';

our $VERSION  = '0.09';

# Regexp for HTML tags

my $SPACE       =  q{\s};
my $IDENT       =  q{[a-zA-Z]+};
my $ATTR_VALUE  =  q{(?: " [^"]* " | ' [^']* ' | [^'"/>/\s]+ )};
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
my $MULTIPLE = q{(?: multiple = (?: "multiple" | 'multiple' | multiple ) )};

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
	return $class->_parse_option(@_);
}

sub _parse_option{
	my $self = shift;

	if(ref $self and not @_){ # as instance method with no option
		return $self;
	}

	my %ctx = (
		ignore_types => {
			button   => 1,
			submit   => 1,
			reset    => 1,
			password => 1,
		},
		target      => undef,

		escape      => \&_escape_html,
	);

	# merge
	foreach my $key( ref($self) ? keys %{$self} : () ){
		my $val = $self->{$key};

		if(ref($val) eq 'HASH'){
			@{ $ctx{$key} }{ keys %{$val} }
				= values %{$val};
		}
		else{
			$ctx{$key} = $val;
		}
	}

	while(my($opt, $val) = splice @_, 0, 2){
		next unless defined $val;

		if(	   $opt eq 'ignore_fields'
			or $opt eq 'disable_fields'
		){
			@{ $ctx{$opt} ||= {} }{ @{$val} }
				= (1) x @{$val};
		}
		elsif($opt eq 'fill_password'){
			$ctx{ignore_types}{password} = !$val;
		}
		elsif($opt eq 'target'){
			$ctx{target} = $val;
		}
		elsif($opt eq 'escape'){
			if($val){
				$ctx{escape} = ref($val) eq 'CODE'
					? $val
					: \&_escape_html;
			}
			else{
				$ctx{escape} = \&_noop;
			}
		}
		elsif($opt eq 'decode_entity'){
			if($val){
				$ctx{decode_entity} = ref($val) eq 'CODE'
					? $val
					: \&_decode_entity;
			}
			else{
				delete $ctx{decode_entity};
			}
		}
		else{
			croak("Unknown option '$opt' suplied");
		}
	}

	return bless \%ctx => ref($self) || $self;
}

sub fill{
	my($self, $src, $q, @opt) = @_;

	if (not defined $src){
		croak('No source suplied');
	}
	if (not defined $q){
		croak('No data suplied');
	}

	my $ctx = $self->_parse_option(@opt);

	### $ctx


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
			open my($in), $src
				or croak("Cannot open '$src': $!");
			$src = $in;
		}
		$content = do{ local $/ = undef; <$src> };
	}
	# only Perl >= 5.8.1
	local $ctx->{utf8} = defined(&utf8::is_utf8)
		? utf8::is_utf8($content)
		: 0;

	# Form data to an object
	local $ctx->{data} =  _to_form_object($q);

	# It's not just a cache. It's needed to implement multi-text fields
	local $ctx->{param_cache} = {};

	# Fill in contents
	if(defined $ctx->{target}){

		$content =~ s{ ($FORM) (.*?) ($END_FORM) }
		             {	my($form, $content, $end_form) = ($1, $2, $3);

				my $id = _get_id($form);
				(defined($id) and $ctx->{target} eq $id)
					? $form . _fill($ctx, $content) . $end_form
					: $form . $content . $end_form
			     }goexmsi;
		return $content;
	}
	else{
		return _fill($ctx, $content);
	}

}

sub _fill{
	my($ctx, $content) = @_;
	$content =~ s{($INPUT)}{ _fill_input($ctx, $1)        }goexmsi;

	$content =~ s{($SELECT) (.*?) ($END_SELECT) }
		     { $1 . _fill_select($ctx, $1, $2) . $3   }goexmsi;

	$content =~ s{($TEXTAREA) (.*?) ($END_TEXTAREA) }
		     { $1 . _fill_textarea($ctx, $1, $2) . $3 }goexmsi;

	return $content;
}

sub _fill_input{
	my($ctx, $tag) = @_;

	### $tag

	my $type = _get_type($tag) || 'text';
	if($ctx->{ignore_types}{ $type }){
		return $tag;
	}

	my $values_ref = $ctx->_get_param(_get_name($tag))
		or return $tag;

	if($type eq 'checkbox' or $type eq 'radio'){
		my $value = _get_value($tag);

		if(not defined $value){
			$value = 'on';
		}
		elsif($ctx->{decode_entity}){
			$value = $ctx->{decode_entity}->($value);
		}

		if(grep { $value eq $_ } @{$values_ref}){
			$tag =~ /$CHECKED/oxmsi
				or $tag =~ s{\s* /? > $}
					    { checked="checked" />}xms;
		}
		else{
			$tag =~ s/\s+$CHECKED//goxmsi;
		}
	}
	else{
		my $new_value = $ctx->{escape}->(shift @{$values_ref});

		$tag =~ s{value = $ATTR_VALUE}{value="$new_value"}oxmsi
			or $tag =~ s{\s* /? > $}
				    { value="$new_value" />}xms;
	}
	return $tag;
}
sub _fill_select{
	my($ctx, $tag, $content) = @_;

	my $values_ref = $ctx->_get_param(_get_name($tag))
		or return $content;

	if($tag !~ /$MULTIPLE/oxmsi){
		$values_ref = [ shift @{ $values_ref } ]; # in select-one
	}

	$content =~ s{($OPTION) (.*?) ($END_OPTION)}
		     { _fill_option($ctx, $values_ref, $1, $2) . $2 . $3 }goexsm;
	return $content;
}
sub _fill_option{
	my($ctx, $values_ref, $tag, $content) = @_;

	my $value = _get_value($tag);
	unless( defined $value ){
		$value = $content;
		$value =~ s{\A $SPACE+   } {}oxms;
		$value =~ s{   $SPACE{2,}}{ }oxms;
		$value =~ s{   $SPACE+ \z} {}oxms;
	}

	if($ctx->{decode_entity}){
		$value = $ctx->{decode_entity}->($value);
	}

	### @_
	if(grep{ $value eq $_ }  @{$values_ref}){
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
	my($ctx, $tag, $content) = @_;

	my $values_ref = $ctx->_get_param(_get_name($tag))
		or return $content;

	return $ctx->{escape}->(shift @{$values_ref});
}

# utilities

sub _get_param{
	my($ctx, $name) = @_;

	return if !defined($name)
		or $ctx->{ignore_fields}{$name};

	my $ref = $ctx->{param_cache}{$name};

	if(not defined $ref){
		$ref = $ctx->{param_cache}{$name}
			= [ $ctx->{data}->param($name) ];

		if($ctx->{utf8}){
			for my $datum( @$ref ){
				utf8::decode($datum)
					unless utf8::is_utf8($datum);
			}
		}
	}

	return @{$ref} ? $ref : undef;
}

sub _noop{
	return $_[0];
}
sub _escape_html{
	my $s = shift;
#	return '' unless defined $s;

	$s =~ s/&/&amp;/g;
	$s =~ s/</&lt;/g;
	$s =~ s/>/&gt;/g;
	$s =~ s/"/&quot;/g;
	return $s;
}
sub _decode_entity{
	my $s = shift;

	if($s =~ /&\w+;/){
		require HTML::Entities;
		return HTML::Entities::decode($s);
	}
	else{
		$s =~ s{&#(\d+);}{chr $1}eg;
		$s =~ s{&#x([0-9a-fA-F]+);}{ chr hex $1}eg;
		return $s;
	}
}

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
#	my $ctx = shift;
#	my $name   = shift;
#
#	if($ctx->{disable_fields}{$name}){
#		$_[0] =~ /$DISABLED/oxmsi
#			or $_[0] =~ s{\s* /? > $}
#				    { disabled="disabled" />}xmsi;
#	}
#	return;
#}

sub _to_form_object{
	my($ref) = @_;

	my $type    = ref $ref;

	# Is it blessed?
	my $blessed = $type ne ''
			&& !!do{ local $@; eval{ $ref->can('VERSION') }};

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
	elsif(not $blessed){
		croak("Cannot use '$ref' as form data");
	}
	elsif($ref->can('param')){ # a request object e.g. CGI.pm
		return $ref;
	}
	else{
		# any object is ok
		$wrapper = \$ref;
		$type    = 'Object';
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
sub HTML::FillInForm::Lite::Object::param{
	my($ref_to_object, $key) = @_;
	my $method = ${$ref_to_object}->can($key)  or return ();
	my(@values) = ${$ref_to_object}->$method();

	return @values == 1 && !defined($values[0]) ? () : @values;
}

1;

__END__

=encoding UTF-8

=head1 NAME

HTML::FillInForm::Lite - Fills in HTML forms with data

=head1 VERSION

The document describes HTML::FillInForm version 0.09

=head1 SYNOPSIS

	use HTML::FillInForm::Lite;
	use CGI;

	my $q = CGI->new();
	my $h = HTML::FillInForm::Lite->new();

	$output = $h->fill(\$html,    $q);
	$output = $h->fill(\@html,    \%data);
	$output = $h->fill(\*HTML,    \&my_param); # yes, \&my_param is ok
	$output = $h->fill('t.html', [$q, \%default]);

	$output = $h->fill(\$html, $q,
		fill_password => 0, # it is default
		ignore_fields => ['foo', 'bar'],
		target        => $form_id,
	);

	# Moreover, it accepts any object as form data
	# (these classes come form Class::DBI's SYNOPSIS)

	my $artist = Music::Artist->insert({ id => 1, name => 'U2' });
	$output = $h->fill(\$html, $artist);

	my $cd = Music::CD->retrieve(1);
	$output = $h->fill(\$html, $cd);

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

=item escape => I<bool> | I<ref>

If true is provided (or by default), values filled in text fields will be
html-escaped, e.g. C<< <tag> >> to be C<< &lt;tag&gt; >>.

If the values are already html-escaped, set the option false.

You can suply a subroutine reference to escape the values.

Note that it is not implemented in C<HTML::FillInForm>.

=item decode_entity => I<bool> | I<ref>

If true is provided, HTML entities in state fields (namely, radio, checkbox
and select) will be decoded. 

You can also suply a subroutine reference to decode HTML entities.

If there are named entities in the fields and the option is true,
C<HTML::Entities> will be required.

Note that it is not implemented in C<HTML::FillInForm>.

=back

=head2 fill(source, form_data [, options...])

Fills in I<source> with I<form_data>.

I<options> are the same as C<new()>'s.

You can use this method as a both class or instance method, 
but you make multiple calls to C<fill()> with the same
options, it is a little faster to call C<new()> before C<fill()>.

To clear all the fields, provide I<form_data> with a subroutine returning an
empty string, like:

	HTML::FillInForm::Lite->fill($source, sub{ '' });

I<form_data> as a subroutine is called in list context. That is, to leave
some fields untouched, it must return C<()>, not C<undef>.

=head1 NOTES

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

No bugs have been reported.

Please report any bug or feature request to E<lt>gfuji(at)cpan.orgE<gt>,
or through L<http://rt.cpan.org>.

=head1 SEE ALSO

L<HTML::FillInForm>.

L<HTML::FillInForm::Lite::JA> - the document in Japanese.

L<HTML::FillInForm::Lite::Compat> - C<HTML::FillInForm> compatibility layer

=head1 AUTHOR

Goro Fuji (藤 吾郎) E<lt>gfuji(at)cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2008 Goro Fuji, Some rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

