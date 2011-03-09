package MyClass;
use Moose;
use ElasticSearch::Document;
use ElasticSearch::Document::Types qw(:all);
use MooseX::Types -declare => ['Resources'];
use MooseX::Types::Structured qw(Dict Tuple Optional);
use MooseX::Types::Moose qw/Int Str ArrayRef HashRef Undef/;

subtype Resources,
  as Dict [ license => Optional [ ArrayRef [Str] ],
            homepage => Optional [Str],
            bugtracker => Optional [ Dict [ web => Str, mailto => Str ] ] ];

has default  => ();
has date     => ( isa => 'DateTime' );
has loc      => ( isa => Location );
has res      => ( isa => Resources );
has abstract => ( analyzer => 'lowercase' );

package main;
use Test::More;
use strict;
use warnings;

is_deeply(
    MyClass->meta->mapping,
    {  
       _source    => { compress => \1 },
       properties => {
           date => { 'store' => 'yes',
                     'type'  => 'date'
           },
           default => { 'index' => 'not_analyzed',
                        'store' => 'yes',
                        'type'  => 'string'
           },
           loc      => { 'type' => 'geo_point' },
           abstract => {
               'type' => 'multi_field',
               fields => {
                   abstract => {

                       'index'  => 'analyzed',
                       analyzer => 'lowercase',
                       'store'  => 'yes',
                       'type'   => 'string'
                   },
                   raw => { 'index' => 'not_analyzed',
                            'store' => 'yes',
                            'type'  => 'string'
                   } }
           },
           res => {
               type       => "object",
               properties => {
                   license => { store => 'yes',
                                type  => 'string',
                                index => 'not_analyzed'
                   },
                   homepage => {

                       store => 'yes',
                       type  => 'string',
                       index => 'not_analyzed'
                   },
                   bugtracker => { type       => 'object',
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
                                   } } } } } } );

done_testing;
