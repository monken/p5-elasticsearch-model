package ElasticSearch::Document::Set;
use Moose;
use MooseX::ChainedAccessors;
use ElasticSearch::Document::Types qw(:all);

has type_class => ( is => 'ro', required => 1 );
has index => ( is => 'ro', required => 1, handles => [qw(es model)] );

has query => ( isa        => 'HashRef',
               is         => 'rw',
               lazy_build => 1,
               traits     => [qw(Chained)] );

has filter => ( isa    => 'HashRef',
                is     => 'rw',
                traits => [qw(Chained)] );

has [qw(from size)] => ( isa => 'Int', is => 'rw', traits => [qw(Chained)] );

has sort => ( isa     => 'ArrayRef',
              traits  => [qw( Array)],
              handles => { add_sort => 'push' } );

has fields => ( isa     => 'ArrayRef',
                traits  => [qw( Array)],
                handles => { add_field => 'push' } );

has mixin => ( isa => 'HashRef', is => 'rw', traits => [qw(Chained)] );

has type => ( isa => QueryType, is => 'rw', traits => [qw(Chained)] );

has version => ( isa => 'Bool', is => 'rw' );

has inflate =>
  ( isa => 'Bool', default => 1, is => 'rw', traits => [qw(Chained)] );

sub _build_query {
    { query => { match_all => {} } };
}

sub as_query { }

sub put {
    my ( $self, $args, $qs ) = @_;
    my $doc = $self->type_class->new_object( %$args, index => $self->index );
    $doc->put($qs);
    return $doc;
}

sub inflate_result {
    my ( $self, $res ) = @_;
    my ( $type, $index ) = ( $res->{_type}, $res->{_index} );
    return $self->model->index($index)->get_type($type)
      ->new_object( $res->{_source} );
}

sub get {
    my ( $self, $args ) = @_;
    my ($id);
    my ( $index, $type ) =
      ( $self->index->name, $self->type_class->short_name );

    if ( !ref $args ) {
        $id = $args;
    } elsif ( my $pk = $self->type_class->get_id_attribute ) {
        my $found = 0;
        my @fields =
          map { $self->type_class->find_attribute_by_name($_) } @{ $pk->id };
        map { $found++ } grep { exists $args->{ $_->name } } @fields;
        die "All id fields need to be supplied to get: @fields"
          unless ( @fields == $found );
        $id = ElasticSearch::Model::Util::digest(
            map {
                    $_->has_deflator
                  ? $_->deflate( $self, $args->{ $_->name } )
                  : $args->{ $_->name }
              } @fields );
    }

    my $res =
      $self->es->transport->request(
                                     { method => 'GET',
                                       cmd    => "/$index/$type/$id"
                                     } );
    return $self->inflate ? $self->inflate_result($res) : $res;
}

sub all {
    my $self = shift;
    my ( $index, $type ) =
      ( $self->index->name, $self->type_class->short_name );
    my $res =
      $self->es->transport->request(
                                     { method => 'POST',
                                       cmd    => "/$index/$type/_search",
                                       data   => $self->query,
                                       qs => { version => 1 }
                                     } );
    return $res unless ( $self->inflate );
    return ()   unless ( $res->{hits}->{total} );
    return map { $self->inflate_result($_) } @{ $res->{hits}->{hits} };

}

sub count {
    my $self = shift;
    my ( $index, $type ) =
      ( $self->index->name, $self->type_class->short_name );
    my $res =
      $self->es->transport->request(
                                     { method => 'POST',
                                       cmd    => "/$index/$type/_search",
                                       data   => {%{$self->query}, size => 0 },
                                     } );
    return $res->{hits}->{total};
}

__PACKAGE__->meta->make_immutable;
