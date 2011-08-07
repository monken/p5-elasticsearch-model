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
