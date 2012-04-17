package ElasticSearchX::Model::Document::Role;
use Moose::Role;
use ElasticSearchX::Model::Util ();
use JSON::XS;
use Digest::SHA1;
use List::MoreUtils ();
use Carp;

sub _does_elasticsearchx_model_document_role {1}

has _inflated_attributes =>
    ( is => 'rw', isa => 'HashRef', lazy => 1, default => sub { {} } );

has index => (
    isa => 'ElasticSearchX::Model::Index',
    is  => 'rw'
);

has _id => (
    is          => 'ro',
    property    => 0,
    source_only => 1,
    traits      => [
        'ElasticSearchX::Model::Document::Trait::Attribute',
        'ElasticSearchX::Model::Document::Trait::Field::ID',
    ],
);
has _version => (
    is          => 'ro',
    property    => 0,
    source_only => 1,
    traits      => [
        'ElasticSearchX::Model::Document::Trait::Attribute',
        'ElasticSearchX::Model::Document::Trait::Field::Version',
    ],
);

sub update {
    my $self = shift;
    return $self->put( { $self->_update(@_) } );
}

sub _update {
    my ( $self, $qs ) = @_;
    $qs ||= {};
    return %$qs if ( exists $qs->{version} );
    my $version = $self->_version;
    die "cannot update document without a version"
        unless ($version);
    return (
        version => $version,
        %$qs
    );
}

sub create {
    my $self = shift;
    return $self->put( { $self->_create(@_) } );
}

sub _create {
    my ( $self, $qs ) = @_;
    my $version = $self->_version;
    return (
        create => 1,
        %{ $qs || {} }

    );
}

sub put {
    my ( $self, $qs ) = @_;
    my $return = $self->index->model->es->index( $self->_put($qs) );
    my $id     = $self->meta->get_id_attribute;
    $id->set_value( $self, $return->{_id} ) if ($id);
    $self->meta->get_attribute('_id')->set_value( $self, $return->{_id} );
    $self->meta->get_attribute('_version')
        ->set_value( $self, $return->{_version} );
    return $self;
}

sub _put {
    my ( $self, $qs ) = @_;
    my $id     = $self->meta->get_id_attribute->get_value($self);
    my $parent = $self->meta->get_parent_attribute;
    my $data   = $self->meta->get_data($self);
    $qs = { %{ $self->meta->get_query_data($self) }, %{ $qs || {} } };
    return (
        index => $self->index->name,
        type  => $self->meta->short_name,
        $id ? ( id => $id ) : (),
        data => $data,
        $parent ? ( parent => $parent->get_value($self) ) : (),
        %$qs,
    );
}

sub delete {
    my ( $self, $qs ) = @_;
    my $id     = $self->meta->get_id_attribute;
    my $return = $self->index->model->es->delete(
        index => $self->index->name,
        type  => $self->meta->short_name,
        id    => $self->_id,
        %{ $qs || {} },
    );
    return $self;
}

sub build_id {
    my $self = shift;
    my $id   = $self->meta->get_id_attribute;
    carp "Need an arrayref of fields for the id, not " . $id->id
        unless ( ref $id->id eq 'ARRAY' );
    my @fields = map { $self->meta->get_attribute($_) } @{ $id->id };
    return ElasticSearchX::Model::Util::digest( map { $_->deflate($self) }
            @fields );
}

1;
