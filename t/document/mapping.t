package MyType;
use Moose;
use ElasticSearchX::Model::Document;

has name => ( is => 'ro', index => 'analyzed' );

package MyClass;
use Moose;
use ElasticSearchX::Model::Document;
use ElasticSearchX::Model::Document::Types qw(:all);
use MooseX::Types -declare => [ 'Resources', 'Profile' ];
use MooseX::Types::Structured qw(Dict Tuple Optional);
use MooseX::Types::Moose qw/Int Str ArrayRef HashRef Undef/;

subtype Resources, as Dict [
    license => Optional [ ArrayRef [Str] ],
    homepage => Optional [Str],
    bugtracker => Optional [ Dict [ web => Str, mailto => Str ] ]
];

subtype Profile, as ArrayRef [ Dict [ id => Str ] ];
coerce Profile, from HashRef, via { [$_] };

has default => ( is => 'ro' );
has profile =>
    ( is => 'ro', isa => Profile, type => 'nested', include_in_root => 1 );
has date => ( is => 'ro', isa            => 'DateTime' );
has pod  => ( is => 'ro', include_in_all => 0 );
has loc  => ( is => 'ro', isa            => Location );
has res  => ( is => 'ro', isa            => Resources );
has abstract => (
    is          => 'ro',
    analyzer    => 'lowercase',
    term_vector => 'with_positions_offsets'
);
has module => (
    is              => 'ro',
    isa             => Type ['MyType'],
    type            => 'nested',
    include_in_root => 1
);
has modules => (
    is              => 'ro',
    isa             => ArrayRef [ Type ['MyType'] ],
    type            => 'nested',
    include_in_root => 1
);
has extra => ( is => 'ro', source_only => 1 );
has vater => ( is => 'ro', parent      => 1 );

package main;
use Test::More;
use strict;
use warnings;

my $meta = MyClass->meta;

is_deeply(
    [ sort map { $_->name } $meta->get_all_properties ],
    [   qw(_id _version abstract date default extra loc module modules pod profile res vater)
    ]
);

my $module  = $meta->get_attribute('module')->build_property;
my $modules = $meta->get_attribute('modules')->build_property;
is_deeply(
    $module,
    {   _source         => { compress => \1 },
        dynamic         => \0,
        type            => 'nested',
        include_in_root => \1,
        properties      => {
            name => {
                fields => {
                    analyzed => {
                        analyzer => "standard",
                        index    => "analyzed",
                        store    => "yes",
                        type     => "string",
                    },
                    name => {
                        index => "not_analyzed",
                        store => "yes",
                        type  => "string",
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
            profile => {
                type            => 'nested',
                include_in_root => \1,
                dynamic         => \0,
                properties      => {
                    id => {
                        index => 'not_analyzed',
                        store => 'yes',
                        type  => 'string',
                    }
                }
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
