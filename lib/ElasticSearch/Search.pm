package ElasticSearch::Search;
use Moose;
use MooseX::ChainedAccessors;
use ElasticSearch::Document::Types qw(:all);

has query => ( isa        => 'HashRef',
               is         => 'rw',
               lazy_build => 1,
               traits     => [qw(Chained)] );

has filter => ( isa    => 'HashRef',
                is     => 'rw',
                traits => [qw(Chained)] );

has [qw(from size)] => ( isa => 'Int', is => 'rw', traits => [qw(Chained)] );

has sort => ( isa => 'ArrayRef', traits => [qw( Array)], handles => { add_sort => 'push' } );

has fields => ( isa => 'ArrayRef', traits => [qw( Array)], handles => { add_field => 'push' } );

has mixin => ( isa => 'HashRef', is => 'rw', traits => [qw(Chained)] );

has raw => ( isa => 'HashRef', is => 'rw', traits => [qw(Chained)] );

has type => ( isa => QueryType, is => 'rw', traits => [qw(Chained)] );

has version => ( isa => 'Bool', is => 'rw' );

has inflate => ( isa => 'Bool', default => 1, is => 'rw' );

sub _build_query {
    { match_all => {} };
}

sub as_query {}

sub count {}

__PACKAGE__->meta->make_immutable;
