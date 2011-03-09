package ElasticSearch::Document;

use strict;
use warnings;

use Moose 1.15 ();
use Moose::Exporter;
use ElasticSearch::Document::Trait::Class;
use ElasticSearch::Document::Trait::Attribute;
use ElasticSearch::Document::Types qw();


my ( undef, undef, $init_meta ) =
  Moose::Exporter->build_import_methods(
         install => [qw(import unimport)],
         class_metaroles => {
             class     => ['ElasticSearch::Document::Trait::Class'],
             attribute => [ 'ElasticSearch::Document::Trait::Attribute',
                            'MooseX::Attribute::Deflator::Meta::Role::Attribute'
             ]
         }, );

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
