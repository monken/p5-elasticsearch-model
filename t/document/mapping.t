package MyType;
use Moose;
use ElasticSearchX::Model::Document;

has name => ( index => 'analyzed' );

package MyClass;
use Moose;
use ElasticSearchX::Model::Document;
use ElasticSearchX::Model::Document::Types qw(:all);
use MooseX::Types -declare => ['Resources'];
use MooseX::Types::Structured qw(Dict Tuple Optional);
use MooseX::Types::Moose qw/Int Str ArrayRef HashRef Undef/;

subtype Resources, as Dict [
    license => Optional [ ArrayRef [Str] ],
    homepage => Optional [Str],
    bugtracker => Optional [ Dict [ web => Str, mailto => Str ] ]
];

has default => ();
has date    => ( isa => 'DateTime' );
has pod     => ( include_in_all => 0 );
has loc     => ( isa => Location );
has res     => ( isa => Resources );
has abstract =>
    ( analyzer => 'lowercase', term_vector => 'with_positions_offsets' );
has module => ( isa => Type ['MyType'] );
has modules => ( isa => ArrayRef [ Type ['MyType'] ] );
has extra => ( source_only => 1 );
has vater => ( parent      => 1 );

package main;
use Test::More;
use strict;
use warnings;

my $meta = MyClass->meta;

is_deeply( [ sort map { $_->name } $meta->get_all_properties ],
    [qw(abstract date default extra loc module modules pod res vater)] );

my $module  = $meta->get_attribute('module')->build_property;
my $modules = $meta->get_attribute('module')->build_property;
is_deeply(
    $module,
    {   _source    => { compress => \1 },
        dynamic    => \0,
        properties => {
            name => {
                fields => {
                    analyzed => {
                        analyzer => "standard",
                        index    => "analyzed",
                        store    => "yes",
                        type     => "string"
                    },
                    name => {
                        index => "not_analyzed",
                        store => "yes",
                        type  => "string"
                    }
                },
                type => "multi_field"
            }
        }
    }
);

is_deeply( $module, $modules );

is_deeply(
    MyClass->meta->mapping,
    {   _source    => { compress => \1 },
        _parent    => { type     => 'vater' },
        dynamic    => \0,
        properties => {
            date => {
                'store' => 'yes',
                'type'  => 'date'
            },
            default => {
                'index' => 'not_analyzed',
                'store' => 'yes',
                'type'  => 'string'
            },
            pod => {
                'index'        => 'not_analyzed',
                'store'        => 'yes',
                'type'         => 'string',
                include_in_all => \0,
            },
            loc      => { 'type' => 'geo_point' },
            module   => $module,
            modules  => $module,
            abstract => {
                'type' => 'multi_field',
                fields => {
                    analyzed => {

                        'index'     => 'analyzed',
                        analyzer    => 'lowercase',
                        'store'     => 'yes',
                        'type'      => 'string',
                        term_vector => 'with_positions_offsets',
                    },
                    abstract => {
                        'index' => 'not_analyzed',
                        'store' => 'yes',
                        'type'  => 'string'
                    }
                }
            },
            res => {
                dynamic    => \0,
                type       => "object",
                properties => {
                    license => {
                        store => 'yes',
                        type  => 'string',
                        index => 'not_analyzed'
                    },
                    homepage => {

                        store => 'yes',
                        type  => 'string',
                        index => 'not_analyzed'
                    },
                    bugtracker => {
                        type       => 'object',
                        dynamic    => \0,
                        properties => {
                            web => {
                                store => 'yes',
                                type  => 'string',
                                index => 'not_analyzed'
                            },
                            mailto => {
                                store => 'yes',
                                type  => 'string',
                                index => 'not_analyzed'
                            },
                        }
                    }
                }
            }
        }
    }
);

done_testing;
