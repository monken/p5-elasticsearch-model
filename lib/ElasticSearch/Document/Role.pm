package ElasticSearch::Document::Role;
use Moose::Role;
use JSON::XS;
use Digest::SHA1;
use List::MoreUtils ();
use Carp;
has index => ( isa      => 'ElasticSearch::Model::Index',
               is       => 'ro',
               property => 0,
               traits   => ['ElasticSearch::Document::Trait::Attribute'] );

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
    my $digest = join( "\0", map { $_->get_value($self) } @fields );
    $digest = Digest::SHA1::sha1_base64($digest);
    $digest =~ tr/[+\/]/-_/;
    return $digest;
}

1;
