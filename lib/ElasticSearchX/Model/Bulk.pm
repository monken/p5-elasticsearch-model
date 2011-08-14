package ElasticSearchX::Model::Bulk;
use Moose;

has stash => (
    is      => 'ro',
    traits  => ['Array'],
    handles => { add => 'push', stash_size => 'count' },
    default => sub { [] },
);
has size => ( is => 'ro', isa => 'Int', default => 100 );
has es => ( is => 'ro' );

sub put {
    my ( $self, $doc ) = @_;
    $self->add( { index => { $doc->_put } } );
    $self->commit if ( $self->stash_size > $self->size );
    return $self;
}

sub delete {
    my ( $self, $doc ) = @_;
    $self->add(
        {   delete => ref $doc eq 'HASH'
            ? $doc
            : { index => $doc->index->name,
                type  => $doc->meta->short_name,
                id    => $doc->_id,
            }
        }
    );
    $self->commit if ( $self->stash_size > $self->size );
    return $self;
}

sub commit {
    my $self = shift;
    return unless($self->stash_size);
    my $result = $self->es->bulk( $self->stash );
    $self->clear;
    return $result;
}

sub clear {
    my $self = shift;
    @{$self->stash} = ();
    return $self;    
}

sub DEMOLISH {
    shift->commit;
}

1;

__END__

=head1 SYNOPSIS

 my $bulk = $model->bulk( size => 10 );
 my $document = $model->index('default')->type('tweet')->new_document({
     message => 'Hello there!',
     date    => DateTime->now,
 });
 $bulk->put( $document );
 $bulk->commit;

=head1 DESCRIPTION

This class is a wrapper around L<ElasticSearch/bulk()> which adds
some convenience. By specifiying a L</size> you set the maximum
number of documents that are processed in one request. You can either
L</put> or L</delete> documents. Once the C<$bulk> object is out
of scope, it will automatically commit its L</stash>. Call L</clear>
if before if you don't want that to happen.

=head1 ATTRIBUTES

=head2 size

The maximum number of documents that are processed in one request.
Once the stash hits that number, a bulk request will be issued
automatically and the stash will be cleared.

=head2 stash

The stash includes the documents that will be processed at the
next commit. A commit is either automatically issued if the size
of the stash is greater then L</size>, if the C<$bulk> object
gets out of scope or if you call L</commit> explicitly.

=head2 es

The L<ElasticSearch> object.

=head1 METHODS

=head2 put

Put a document. Accepts a document object (see 
L<ElasticSearchX::Model::Document::Set/new_document>).

=head2 delete

Delete a document. You can either pass a document object or a
HashRef that consists of C<index>, C<type> and C<id>.

=head2 commit

Commits the documents in the stash to ElasticSearch.

=head2 clear

Clears the stash.

=head2 stash_size

Returns the number of documents in the stash.