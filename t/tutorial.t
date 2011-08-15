package MyModel::Tweet;
use Moose;
use ElasticSearchX::Model::Document;

has id        => ( is => 'ro', id  => [qw(user post_date)] );
has user      => ( is => 'ro', isa => 'Str' );
has post_date => ( is => 'ro', isa => 'DateTime' );
has message   => ( is => 'ro', isa => 'Str' );

package MyModel::User;
use Moose;
use ElasticSearchX::Model::Document;

has nickname => ( is => 'ro', isa => 'Str', id => 1 );
has name => ( is => 'ro', isa => 'Str' );

package MyModel;
use Moose;
use ElasticSearchX::Model;

index twitter => ( namespace => 'MyModel' );

package main;
use Test::Most;
use IO::Socket::INET;

unless ( IO::Socket::INET->new('127.0.0.1:9900') ) {
    plan skip_all => 'Requires an ElasticSearch server running on port 9900';
}

my $model = MyModel->new( es => ':9900' );
ok( $model->deploy( delete => 1 ), 'Deploy ok' );

use DateTime;

my $twitter   = $model->index('twitter');
my $timestamp = DateTime->now;
ok( my $tweet = $twitter->type('tweet')->put(
        {   user      => 'mo',
            post_date => $timestamp,
            message   => 'Elastic baby!',
        },
        { refresh => 1 }
    ),
    'Put ok'
);

my $tweets = $twitter->type('tweet');

is( $tweets->count, 1, 'Count ok' );

throws_ok {
    $twitter->type('tweet')->get( { post_date => $timestamp, } );
}
qr/fields/;

ok( $tweets->get( $tweet->id ), 'Get tweet by id' );

ok( $tweet = $tweets->get(
        {   user      => 'mo',
            post_date => $timestamp,
        }
    ),
    'Get tweet by key/values'
);

isa_ok( $tweet->post_date, 'DateTime' );
my $raw = {
    _id     => $tweet->id,
    _index  => "twitter",
    _source => {
        id        => $tweet->id,
        message   => "Elastic baby!",
        post_date => $timestamp->iso8601,
        user      => "mo"
    },
    _type    => "tweet",
    _version => 1
};
is_deeply(
    $tweets->inflate(0)->get( $tweet->id ),
    { %$raw, exists => 'true' },
    'Raw response'
);

is_deeply(
    $tweets->all->{hits},
    { hits => [ { %$raw, _score => 1 } ], max_score => 1, total => 1 },
    'Raw all response'
);

done_testing;
