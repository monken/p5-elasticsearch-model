package ElasticSearchX::Model::Document::Set;
use Moose;
use MooseX::ChainedAccessors;
use ElasticSearchX::Model::Document::Types qw(:all);

has type => ( is => 'ro', required => 1 );
has index => ( is => 'ro', required => 1, handles => [qw(es model)] );

has query => (
    isa        => 'HashRef',
    is         => 'rw',
    lazy_build => 1,
    traits     => [qw(Chained)]
);

has filter => (
    isa    => 'HashRef',
    is     => 'rw',
    traits => [qw(Chained)]
);

has filtered => ( isa => 'Bool', is => 'rw', traits => [qw(Chained)] );

has [qw(from size)] => ( isa => 'Int', is => 'rw', traits => [qw(Chained)] );

has sort => (
    isa    => 'ArrayRef',
    is     => 'rw',
    traits => [qw(Chained)]
);

sub add_sort { push( @{ $_[0]->sort }, $_[1] ); return $_[0]; }

has fields => (
    isa    => 'ArrayRef',
    is     => 'rw',
    traits => [qw(Chained)]
);

sub add_field { push( @{ $_[0]->fields }, $_[1] ); return $_[0]; }

has mixin => ( isa => 'HashRef', is => 'rw', traits => [qw(Chained)] );

has query_type => ( isa => QueryType, is => 'rw', traits => [qw(Chained)] );

has version => ( isa => 'Bool', is => 'rw' );

has inflate =>
    ( isa => 'Bool', default => 1, is => 'rw', traits => [qw(Chained)] );

sub _build_query {
    my $self = shift;
    {   query => {
            $self->filter
            ? ( filtered => {
                    query  => { match_all => {} },
                    filter => $self->filter
                }
                )
            : ( match_all => {} )

        },
        $self->size ? ( size => $self->size ) : (),
        $self->from ? ( size => $self->from ) : (),
    };
}

sub as_query { }

sub put {
    my ( $self, $args, $qs ) = @_;
    my $doc = $self->new_document($args);
    $doc->put($qs);
    return $doc;
}

sub new_document {
    my ( $self, $args ) = @_;
    return $self->type->new_object( %$args, index => $self->index );
}

sub inflate_result {
    my ( $self, $res ) = @_;
    my ( $type, $index ) = ( $res->{_type}, $res->{_index} );
    $index = $index ? $self->model->index($index) : $self->index;
    $type  = $type  ? $index->get_type($type)     : $self->type;
    my $id     = $type->get_id_attribute;
    my $parent = $type->get_parent_attribute;
    return $type->new_object(
        {   %{ $res->{_source} || {} },
            index => $index,
            _id   => $res->{_id},
            $id     ? ( $id->name     => $res->{_id} )     : (),
            $parent ? ( $parent->name => $res->{_parent} ) : (),
        }
    );
}

sub get {
    my ( $self, $args ) = @_;
    my ($id);
    my ( $index, $type ) = ( $self->index->name, $self->type->short_name );

    if ( !ref $args ) {
        $id = $args;
    }
    elsif ( my $pk = $self->type->get_id_attribute ) {
        my $found = 0;
        my @fields
            = map { $self->type->find_attribute_by_name($_) } @{ $pk->id };
        map { $found++ } grep { exists $args->{ $_->name } } @fields;
        die "All id fields need to be supplied to get: @fields"
            unless ( @fields == $found );
        $id = ElasticSearchX::Model::Util::digest(
            map {
                      $_->has_deflator
                    ? $_->deflate( $self, $args->{ $_->name } )
                    : $args->{ $_->name }
                } @fields
        );
    }

    my $res = eval {
        $self->es->transport->request(
            {   method => 'GET',
                cmd    => "/$index/$type/$id"
            }
        );
    };
    return undef unless ($res);
    return $self->inflate ? $self->inflate_result($res) : $res;
}

sub all {
    my $self = shift;
    my ( $index, $type ) = ( $self->index->name, $self->type->short_name );
    my $res = $self->es->transport->request(
        {   method => 'POST',
            cmd    => "/$index/$type/_search",
            data   => $self->query,
            qs     => { version => 1 }
        }
    );
    return $res unless ( $self->inflate );
    return ()   unless ( $res->{hits}->{total} );
    return map { $self->inflate_result($_) } @{ $res->{hits}->{hits} };
}

sub first {
    my $self  = shift;
    my $query = $self->query;
    my @data  = $self->query( { %$query, size => 1 } )->all;
    return undef unless (@data);
    return $data[0] if ( $self->inflate );
    return $data[0]->{hits}->{hits}->[0];
}

sub count {
    my $self = shift;
    my ( $index, $type ) = ( $self->index->name, $self->type->short_name );
    my $res = $self->es->transport->request(
        {   method => 'POST',
            cmd    => "/$index/$type/_search",
            data   => { %{ $self->query }, size => 0 },
        }
    );
    return $res->{hits}->{total};
}

__PACKAGE__->meta->make_immutable;
