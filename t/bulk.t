package MyModel::User;
use Moose;
use ElasticSearchX::Model::Document;

package MyModel::Tweet;
use Moose;
use ElasticSearchX::Model::Document;

has text => ( is => 'ro' );

package MyModel;
use Moose;
use ElasticSearchX::Model;

__PACKAGE__->meta->make_immutable;

package main;
use Test::Most;
use strict;
use warnings;

ok( my $model = MyModel->new, 'Created object' );

my $stash;
{
    ok( my $bulk = $model->bulk, 'bulk object' );
    $stash = $bulk->stash;
    $bulk->put( $model->index('default')->type('tweet')
            ->new_document( { text => 'foo' } ) );
    is($bulk->stash_size, 1, 'stash size is 1');
}

is_deeply($stash, [], 'stash has been commited');


done_testing;
