package ElasticSearchX::Model::Document::Trait::Field::TTL;

use Moose::Role;
use ElasticSearchX::Model::Document::Types qw(:all);

has ttl => (
    is        => 'rw',
    isa       => TTLField,
    coerce    => 1,
    predicate => 'has_ttl',
);

around mapping => sub { () };

around type_mapping => sub {
    my ( $orig, $self ) = @_;
    my $default = $self->default($self);
    return ( _ttl => $self->ttl );
};

around field_name => sub {'_ttl'};

around property => sub {0};

1;
