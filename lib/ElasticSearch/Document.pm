package ElasticSearch::Document;

use strict;
use warnings;

use Moose 1.15 ();
use Moose::Exporter;
use ElasticSearch::Document::Trait::Class;
use ElasticSearch::Document::Trait::Attribute;
use ElasticSearch::Document::Types qw();
use JSON::XS;
use Digest::SHA1;
use List::MoreUtils ();
use Carp;

Moose::Exporter->setup_import_methods(
                    as_is           => [qw(_build_es_id put _put)],
                    class_metaroles => {
                        class     => ['ElasticSearch::Document::Trait::Class'],
                        attribute => [
                            'ElasticSearch::Document::Trait::Attribute',
                            'MooseX::Attribute::Deflator::Meta::Role::Attribute'
                        ]
                    }, );


sub put {
    my ( $self, $es ) = @_;
    my $id = $self->meta->get_id_attribute;
    return $es->index( $self->_index );
}

sub _put {
    my ($self) = @_;
    my $id = $self->meta->get_id_attribute;

    return ( index => 'cpan',
             type  => $self->meta->short_name,
             $id ? ( id => $id->get_value($self) ) : (),
             data => $self->meta->get_data($self), );
}

sub _build_es_id {
    my $self = shift;
    my $id   = $self->meta->get_id_attribute;
    carp "Need an arrayref of fields for the id, not " . $id->id
      unless ( ref $id->id eq 'ARRAY' );
    my @fields = map { $self->meta->get_attribute($_) } @{ $id->id };
    my $digest = join( "\0", map { $_->get_value($self) } @fields );
    $digest = Digest::SHA1::sha1_base64($digest);
    $digest =~ tr/[+\/]/-_/;
    return $digest;
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