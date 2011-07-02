package ElasticSearchX::Model::Document::Role;
use Moose::Role;
use ElasticSearchX::Model::Util ();
use JSON::XS;
use Digest::SHA1;
use List::MoreUtils ();
use Carp;

has _inflated_attributes => ( is => 'rw', isa => 'HashRef', lazy => 1, default => sub {{}} );

has index => ( isa      => 'ElasticSearchX::Model::Index',
               is       => 'rw' );

has _id => ( is => 'ro' );

sub put {
    my ( $self, $qs ) = @_;
    return $self->index->model->es->index( $self->_put, %$qs );
}

sub _put {
    my ($self) = @_;
    my $id = $self->meta->get_id_attribute;

    return ( index => $self->index->name,
             type  => $self->meta->short_name,
             $id ? ( id => $id->get_value($self) ) : (),
             data => $self->meta->get_data($self), );
}

sub build_id {
    my $self = shift;
    my $id   = $self->meta->get_id_attribute;
    carp "Need an arrayref of fields for the id, not " . $id->id
      unless ( ref $id->id eq 'ARRAY' );
    my @fields = map { $self->meta->get_attribute($_) } @{ $id->id };
    return ElasticSearchX::Model::Util::digest(map { $_->deflate($self) } @fields);
}

1;
