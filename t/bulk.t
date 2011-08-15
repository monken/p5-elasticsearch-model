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
use Test::MockObject::Extends;
use strict;
use warnings;

my $es = Test::MockObject::Extends->new( ElasticSearch->new );
my $i  = 0;
$es->mock( bulk => sub { $i++ } );

ok( my $model = MyModel->new( es => $es ), 'Created object' );

my $stash;
{
    ok( my $bulk = $model->bulk, 'bulk object' );
    $stash = $bulk->stash;
    $bulk->put( $model->index('default')->type('tweet')
            ->new_document( { text => 'foo' } ) );
    is( $bulk->stash_size, 1, 'stash size is 1' );
    ok( !$i, "bulk not yet called" );
}
ok( $i, "bulk was called" );

is_deeply( $stash, [], 'stash has been commited' );

done_testing;
