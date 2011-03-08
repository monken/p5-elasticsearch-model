package MyModel::Twitter::User;
use Moose;
use ElasticSearch::Document;

package MyModel::Twitter::Tweet;
use Moose;
use ElasticSearch::Document;

package MyModel::IRC::User;
use Moose;
extends 'MyModel::Twitter::User';

package MyModel;
use Moose;
use ElasticSearch::Model;

analyzer lowercase => ( tokenizer => 'keyword',  filter   => 'lowercase' );
analyzer fulltext  => ( type      => 'snowball', language => 'English' );

index twitter => ( namespace => 'MyModel::Twitter' );
index irc     => ( namespace => 'MyModel::IRC' );

__PACKAGE__->meta->make_immutable;

package main;
use Test::Most;
use strict;
use warnings;

ok( my $model = MyModel->new(), 'Created object ok' );
my $meta = $model->meta;

is_deeply( [ $meta->get_index_list ],
           [ 'irc', 'twitter' ],
           'Has index twitter' );

ok( my $idx = $model->index('twitter'), 'Get index twitter' );

is_deeply( $idx->types,
           {  user  => MyModel::Twitter::User->meta,
              tweet => MyModel::Twitter::Tweet->meta
           },
           'Types loaded ok' );

ok( $idx = $idx->model->index('irc'), 'Switch index' );

isa_ok( $idx, 'ElasticSearch::Index' );

is_deeply( $idx->types,
           { user => MyModel::IRC::User->meta },
           'Types loaded ok' );

done_testing;
