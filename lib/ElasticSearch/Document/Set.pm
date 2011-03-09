package ElasticSearch::Document::Set;
use Moose;
use MooseX::ChainedAccessors;
use ElasticSearch::Document::Types qw(:all);

has type => ( is => 'ro', required => 1 );
has index => ( is => 'ro', required => 1, handles => [qw(es)] );

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

#has type => ( isa => QueryType, is => 'rw', traits => [qw(Chained)] );

has version => ( isa => 'Bool', is => 'rw' );

has inflate => ( isa => 'Bool', default => 1, is => 'rw' );

sub _build_query {
    { match_all => {} };
}

sub as_query {}

sub put {
    my ($self, $args, $qs) = @_;
    my $doc = $self->type->new_object(%$args, index => $self->index);
    return $doc->put($qs);
}

sub inflate_result {
    
}

sub count {
    my $self = shift;
    my ($index, $type) = ( $self->index->name, $self->type->short_name );
#    $self->es->refresh_index;
    my $res = $self->es->transport->request({
        method => 'POST',
        cmd => "/$index/$type/_count",
        data => $self->query,
    });
    return $res->{count};
}

__PACKAGE__->meta->make_immutable;