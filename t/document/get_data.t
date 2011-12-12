package MyModel::MyType;
use Moose;
use ElasticSearchX::Model::Document;

has name => ( is => 'ro', index => 'analyzed' );

package MyModel::MyClass;
use Moose;
use ElasticSearchX::Model::Document;
use ElasticSearchX::Model::Document::Types qw(:all);

has module => ( is => 'ro', isa => Type ['MyType'] );
has hash => ( is => 'ro', isa => 'HashRef' );
has hash_dynamic =>
    ( is => 'ro', isa => 'HashRef', dynamic => 1 );
has author => ( is => 'ro' );
has extra => ( is => 'ro', source_only => 1, dynamic => 1 );
has [qw(bool1 bool2)] => ( is => 'ro', isa => 'Bool' );

MyModel::MyClass->meta->make_immutable;

package MyModel;
use Moose;
use ElasticSearchX::Model;

index static  => ( dynamic => 0 );
index dynamic => ( dynamic => 1 );

MyModel->meta->make_immutable;

package main;
use Test::More;
use strict;
use warnings;

my $model = MyModel->new;

{
    my $meta = MyModel::MyClass->meta;
    my $obj  = MyModel::MyClass->new(
        module => MyModel::MyType->new( name => 'foo' ),
        author => 'me',
    );

    ok( $meta->get_attribute('module')->has_deflator, 'module has deflator' );
    ok( $meta->get_attribute('module')->has_type_constraint,
        'module has tc' );

    is_deeply( $meta->get_data($obj),
        { author => 'me', module => { name => 'foo' } },
        'deflated ok' );
}

{
    my $doc = MyModel::MyClass->new(
        hash         => { foo => 'bar' },
        hash_dynamic => { foo => 'bar' },
        index        => $model->index('static')
    );

    is( MyModel::MyClass->meta->get_attribute('hash')->deflate($doc),
        '{"foo":"bar"}',
        'static attr deflates to json'
    );
    is_deeply(
        MyModel::MyClass->meta->get_attribute('hash_dynamic')->deflate($doc),
        { foo => 'bar' },
        'dynamic attr doesn\'t deflate'
    );

}

{

    my $doc = MyModel::MyClass->new(
        author       => undef,
        hash_dynamic => { foo => 1 },
        index        => $model->index('static')
    );
    is_deeply(
        $doc->meta->get_data($doc),
        { hash_dynamic => { foo => 1 } },
        'don\'t store undef fields'
    );
}

{
    my $doc = MyModel::MyClass->new(
        extra => { foo => 'bar' },
        index => $model->index('static')
    );
    is_deeply(
        $doc->meta->get_data($doc),
        { extra => { foo => 'bar' } },
        'extra field is included'
    );
}

{
    my $doc = MyModel::MyClass->new(
        bool1 => 1,
        bool2 => 1,
        index => $model->index('static')
    );
    my $deflated1 = $doc->meta->get_attribute('bool1')->deflate($doc);
    ok($deflated1, "deflated is true");
    my $deflated2 = $doc->meta->get_attribute('bool2')->deflate($doc);
    ok($deflated2, "deflated is false");
}

done_testing;
