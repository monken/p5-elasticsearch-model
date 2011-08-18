package ElasticSearchX::Model::Document::Set;
use Moose;
use MooseX::ChainedAccessors;
use ElasticSearchX::Model::Scroll;
use ElasticSearchX::Model::Document::Types qw(:all);

has type => ( is => 'ro', required => 1 );
has index => ( is => 'ro', required => 1, handles => [qw(es model)] );

has query => (
    isa    => 'HashRef',
    is     => 'rw',
    traits => [qw(Chained)]
);

has filter => (
    isa    => 'HashRef',
    is     => 'rw',
    traits => [qw(Chained)]
);

has [qw(from size)] => ( isa => 'Int', is => 'rw', traits => [qw(Chained)] );

has [qw(fields sort)] => (
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

has query_type => ( isa => QueryType, is => 'rw', traits => [qw(Chained)] );

has mixin => ( is => 'ro', isa => 'HashRef', traits => [qw(Chained)] );

has inflate =>
    ( isa => 'Bool', default => 1, is => 'rw', traits => [qw(Chained)] );

sub raw {
    shift->inflate(0);
}

sub _build_query {
    my $self = shift;
    my $query
        = { query => $self->query ? $self->query : { match_all => {} } };
    $query->{filter} = $self->filter if ( $self->filter );
    $query = { query => { filtered => $query } }
        if ( $self->filter && !$self->query );
    my $q = {
        %$query,
        $self->size   ? ( size   => $self->size )   : (),
        $self->from   ? ( from   => $self->from )   : (),
        $self->fields ? ( fields => $self->fields ) : (),
        $self->sort   ? ( sort   => $self->sort )   : (),
        $self->mixin ? ( %{ $self->mixin } ) : (),
    };

    return $q;
}

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
            data   => $self->_build_query,
            qs     => { version => 1 }
        }
    );
    return $res unless ( $self->inflate );
    return ()   unless ( $res->{hits}->{total} );
    return map { $self->inflate_result($_) } @{ $res->{hits}->{hits} };
}

sub first {
    my $self = shift;
    my @data = $self->size(1)->all;
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
            data   => { %{ $self->_build_query }, size => 0 },
        }
    );
    return $res->{hits}->{total};
}

sub scroll {
    my ( $self, $scroll ) = @_;
    return ElasticSearchX::Model::Scroll->new(
        set => $self,
        scroll => $scroll || '1m'
    );
}

__PACKAGE__->meta->make_immutable;

=head1 SYNOPSIS

 my $type = $model->index('default')->type('tweet');
 my $all  = $type->all;

 my $result = $type->filter( { term => { message => 'hello' } } )->first;
 
 my $tweet
    = $type->get( { user => 'mo', post_date => DateTime->now->iso8601 } );


 package MyModel::Tweet::Set;
 
 use Moose;
 extends 'ElasticSearchX::Model::Document::Set';
 
 sub hello {
     my $self = shift;
     return $self->filter({
         term => { message => 'hello' }
     });
 }
 
 __PACKAGE__->meta->make_immutable;
 
 my $result = $type->hello->first;

=head1 DESCRIPTION

Whenever a type is accessed by calling L<ElasticSearchX::Model::Index/type>
you will receive an instance of this class.  The instance can then be used
to build new objects (L</new_document>), put new documents in the index
(L</put>), do search and so on.

=head1 SUBCLASSING

If you define a C<::Set> class on top of your document class, this class
will be used as set class. This allows you to put most of your business
logic in this class.

=head1 ATTRIBUTES

All attributes can be chained, i.e. all of them return the
object and not the value that was passed to it.

=head2 filter

Adds a filter to the query. If no L</query> is given, it will automatically
build a C<filtered> query, which performs far better.

=head2 query

=head2 size

=head2 from

=head2 fields

=head2 sort

These attributes are passed directly to the ElasticSearch search request.

=head2 mixin

The previously mentioned attributes don't cover all of
ElasticSearch's options for searching. You can set the
L</mixin> attribute to a HashRef which is then merged with
the attributes.

=head2 inflate

Inflate the returned results to the appropriate document
object. Defaults to C<1>. You can either use C<$type->inflate(0)>
to disable this behaviour for extra speed, or you can
use the L</raw> convenience method.

=head2 index

=head2 type

=head1 METHODS

=head2 all

Returns all results as a list, limited by L</size> and L</from>.

=head2 first

Returns the first result only. It automatically sets
L</size> to C<1> to speed up the retrieval. However,
it doesn't touch L</from>. In order to get the second
result, you would do:

 my $second = $type->from(2)->first;

=head2 count

Returns the number of results.

=head2 get

 $type->get('fd_ZGWupT2KOxw3w9Q7VSA');
 
 $type->get({
     user => 'mo',
     post_date => $dt->iso8601,
 });

Get a document by its id from ElasticSearch. You can either
pass the id as a string or you can pass a HashRef of
the values that make up the id.

=head2 put

 my $doc = $type->put({
     message => 'hello',
 });

This methods builds a new document using L</new_document> and
pushes it to the index. It returns the created document. If
no id was supplied, the id will be fetched from ElasticSearch
and set on the object in the C<_id> attribute.

=head2 new_document

 my $doc = $type->new_document({
      message => 'hello',
  });

Builds a new document but doesn't commit it just yet. You
can manually commit the new document by calling
L<ElasticSearchX::Model::Document/put> on the document
object.

=head2 raw

Don't inflate returned results. This is a convenience
method around L</inflate>.
