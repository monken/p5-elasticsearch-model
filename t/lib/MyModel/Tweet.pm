package MyModel::Tweet;
use Moose;
use ElasticSearchX::Model::Document;
use DateTime;

has id        => ( is => 'ro', id  => [qw(user post_date)] );
has user      => ( is => 'ro', isa => 'Str' );
has name      => ( is => 'ro', isa => 'Str' );
has post_date => ( is => 'ro', isa => 'DateTime', default => sub { DateTime->now } );
has message   => ( is => 'rw', isa => 'Str', index => 'analyzed' );

__PACKAGE__->meta->make_immutable;