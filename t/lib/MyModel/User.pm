package MyModel::User;
use Moose;
use ElasticSearchX::Model::Document;

has nickname => ( is => 'ro', isa => 'Str', id => 1 );
has name => ( is => 'ro', isa => 'Str' );

__PACKAGE__->meta->make_immutable;