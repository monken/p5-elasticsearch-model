package Foo;
use Moose;
use ElasticSearch::Document;

has some => ( is => 'ro' );
has name => ( is => 'ro', id => 1 );

use Test::More;
use strict;
use warnings;

use ElasticSearch::Document::Bulk;

ok(!$ElasticSearch::Document::Bulk::BULK);

bulk {
    ok($ElasticSearch::Document::Bulk::BULK);
    ok(ElasticSearch::Document::Bulk::is_bulk);
};

ok(!$ElasticSearch::Document::Bulk::BULK);
ok(!ElasticSearch::Document::Bulk::is_bulk);


done_testing;