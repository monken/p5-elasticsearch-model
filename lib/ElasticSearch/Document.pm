package ElasticSearch::Document;

use strict;
use warnings;

use Moose 1.15 ();
use Moose::Exporter;
use ElasticSearch::Document::Trait::Class;
use ElasticSearch::Document::Trait::Attribute;
use ElasticSearch::Document::Types qw();

my ( undef, undef, $init_meta ) = Moose::Exporter->build_import_methods(
    install         => [qw(import unimport)],
    with_meta       => [qw(has)],
    class_metaroles => {
        constructor =>
          ['MooseX::Attribute::LazyInflator::Meta::Role::Method::Constructor'],
        class     => ['ElasticSearch::Document::Trait::Class']
    }, );

sub has {
    my $meta = shift;
    my $name = shift;

    Moose->throw_error('Usage: has \'name\' => ( key => value, ... )')
      if @_ % 2 == 1;
    my %options = ( definition_context => Moose::Util::_caller_info(), @_ );
    $options{traits} ||= [];
    push(@{$options{traits}}, 'ElasticSearch::Document::Trait::Attribute')
        if($options{property} || !exists $options{property});
    delete $options{property};
    
    $options{required} = 1    unless ( exists $options{required} );
    $options{is}       = 'ro' unless ( exists $options{is} );
    my $attrs = ( ref($name) eq 'ARRAY' ) ? $name : [ ($name) ];
    $meta->add_attribute( $_, %options ) for @$attrs;
}

sub init_meta {
    my $class = shift;
    my %p     = @_;
    Moose::Util::ensure_all_roles( $p{for_class},
                                   qw(ElasticSearch::Document::Role) );
    $class->$init_meta(%p);
}

1;

__END__

=head1 SYNOPSIS

 package MyClass;
 use Moose;
 use ElasticSearch::Document;
 use ElasticSearch::Document::Types qw(:all);
 use MooseX::Types -declare => ['Resources'];
 use MooseX::Types::Structured qw(Dict Tuple Optional);
 use MooseX::Types::Moose qw/Int Str ArrayRef HashRef Undef/;

 subtype Resources,
  as Dict [ license => Optional [ ArrayRef [Str] ],
            homepage => Optional [Str],
            bugtracker => Optional [ Dict [ web => Str, mailto => Str ] ] ];

 has default  => ();
 has date     => ( isa => 'DateTime' );
 has location => ( isa => Location );
 has res      => ( isa => Resources );
 has abstract => ( analyzer => 'lowercase' );

=head1 DESCRIPTION

This class extends Moose to include meta information for ElasticSearch.
By default, each attribute is treated as property of an ElasticSearch
type. The type name is derived from the class name. See
L<ElasticSearch::Document::Trait::Class>.

See L<ElasticSearch::Document::Trait::Attribute/ATTRIBUTES> for a full 
list of attribute options available.

B<< All attributes are C<required> and C<ro> by default. >>

=head1 METHODS

=head2 put

This puts a document to the ElasticSearch server. It calls
L<ElasticSearch::Document::Trait::Class/get_data> to retrieve the
data from an L<ElasticSearch::Document> object.
