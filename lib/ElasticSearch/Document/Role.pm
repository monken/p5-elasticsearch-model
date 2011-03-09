package ElasticSearch::Document::Role;
use Moose::Role;
use ElasticSearch::Model::Util ();
use JSON::XS;
use Digest::SHA1;
use List::MoreUtils ();
use Carp;
has _inflated_attributes => ( is => 'rw', isa => 'HashRef', lazy => 1, default => sub {{}} );

sub _lazy_attributes {}
after _inflated_attributes => sub { warn "someone called" };

has index => ( isa      => 'ElasticSearch::Model::Index',
               is       => 'ro' );

sub put {
    my ( $self, $qs ) = @_;
    my $id = $self->meta->get_id_attribute;
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
    return ElasticSearch::Model::Util::digest(map {
            $_->has_deflator ? $_->deflate($self) : $_->get_value($self)
       } @fields);
}

1;
