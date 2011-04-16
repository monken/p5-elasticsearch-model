package MyType;
use Moose;
use ElasticSearchX::Model::Document;

has name => ( index => 'analyzed' );

package MyClass;
use Moose;
use ElasticSearchX::Model::Document;
use ElasticSearchX::Model::Document::Types qw(:all);


has module => ( isa => Type ['MyType'] );
has author => ();



package main;
use Test::More;
use strict;
use warnings;

my $meta = MyClass->meta;
my $obj = MyClass->new(
    module => MyType->new( name => 'foo' ),
    author => 'me',
);

ok( $meta->get_attribute('module')->has_deflator, 'module has deflator');
ok( $meta->get_attribute('module')->has_type_constraint, 'module has tc');

is_deeply($meta->get_data($obj), { author => 'me', module => { name => 'foo' }}, 'deflated ok');

done_testing;
