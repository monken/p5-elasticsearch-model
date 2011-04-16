package Foo;
use Moose;
use ElasticSearchX::Model::Document;

has some => ( is => 'ro' );
has name => ( is => 'ro', id => 1 );

use Test::More;
use strict;
use warnings;

use ElasticSearchX::Model::Document::Bulk;

ok(!$ElasticSearchX::Model::Document::Bulk::BULK);

bulk {
    ok($ElasticSearchX::Model::Document::Bulk::BULK);
    ok(ElasticSearchX::Model::Document::Bulk::is_bulk);
};

ok(!$ElasticSearchX::Model::Document::Bulk::BULK);
ok(!ElasticSearchX::Model::Document::Bulk::is_bulk);


done_testing;