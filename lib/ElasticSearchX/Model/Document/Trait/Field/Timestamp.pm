package ElasticSearchX::Model::Document::Trait::Field::Timestamp;
use Moose::Role;
use ElasticSearchX::Model::Document::Types qw(:all);

has timestamp => (
    is        => 'rw',
    isa       => TimestampField,
    coerce    => 1,
    predicate => 'has_timestamp',
);

around mapping => sub { () };

around type_mapping => sub {
    my ( $orig, $self ) = @_;
    return ( _timestamp => $self->timestamp );
};

around field_name => sub {'_timestamp'};

around query_property => sub {1};

around property => sub {0};

package ElasticSearchX::Model::Document::Trait::Class::Timestamp;
use Moose::Role;

1;
