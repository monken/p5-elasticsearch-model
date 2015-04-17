package MyModel;
use Moose;
use Test::More;
use IO::Socket::INET;
use ElasticSearchX::Model;
use Search::Elasticsearch;
use version;

index twitter => ( namespace => 'MyModel' );

sub testing {
    my $class = shift;
    unless ( IO::Socket::INET->new('127.0.0.1:9900') ) {
        plan skip_all =>
            'Requires an Elasticsearch server running on port 9900';
    }

    my $model = $class->new( es => Search::Elasticsearch->new(
        nodes => $ENV{ES}||"localhost:9900",
        # trace_to => "Stderr",
    ) );
    if ( $model->es_version < 1 ) {
        plan skip_all => 'Requires Elasticsearch 1.0.0';
    }

    ok( $model->deploy( delete => 1 ), 'Deploy ok' );
    return $model;
}

__PACKAGE__->meta->make_immutable;
