package MyModel::User;
use Moose;
use ElasticSearchX::Model::Document;
use DateTime;

has nickname => ( is => 'ro', isa => 'Str', id => 1 );
has name => ( is => 'ro', isa => 'Str' );
has updated =>
    ( is => 'ro', isa => 'DateTime', default => sub { DateTime->now } );

has timestamp => ( timestamp => 1, is => 'ro', isa => 'DateTime' );

has ttl => ( ttl => 1, is => 'ro' );

__PACKAGE__->meta->make_immutable;
