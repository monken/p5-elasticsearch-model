package MyModel::Tweet;
use Moose;
use ElasticSearch::Document;

has id => ( id => [qw(user post_date)] );
has user => ( isa => 'Str' );
has post_date => ( isa => 'DateTime' );
has message => ( isa => 'Str' );

package MyModel::User;
use Moose;
use ElasticSearch::Document;

has nickname => ( isa => 'Str', id => 1 );
has name => ( isa => 'Str' );

package MyModel;
use Moose;
use ElasticSearch::Model;

index twitter => ( namespace => 'MyModel' );

package main;
use Test::Most;

my $model = MyModel->new;
ok($model->deploy, 'Deploy ok');

use DateTime;

my $twitter = $model->index('twitter');
ok($twitter->type('tweet')->put({
    user => 'mo',
    post_date => DateTime->now,
    message => 'Elastic baby!',
}, { refresh => 1 }), 'Put ok');

is($twitter->type('tweet')->count, 1, 'Count ok');

done_testing;