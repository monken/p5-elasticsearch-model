package ElasticSearch::Document::Trait::Attribute;
use Moose::Role;
use ElasticSearch::Document::Mapping;

has property => ( is => 'ro', isa => 'Bool', default => 1 );

has id => ( is => 'ro', isa => 'Bool|ArrayRef', default => 0 );
has index  => ( is => 'ro' );
has boost  => ( is => 'ro', isa        => 'Num' );
has store  => ( is => 'ro', isa        => 'Str', default => 'yes' );
has type   => ( is => 'ro', isa        => 'Str', default => 'string' );
has parent => ( is => 'ro', isa        => 'Bool', default => 0 );
has dynamic => ( is => 'ro', isa        => 'Bool', default => 1 );
has analyzer => ( is => 'ro', isa => 'Str' );

sub is_property { shift->property }

sub es_properties {
    my $self = shift;
    return { ElasticSearch::Document::Mapping::maptc($self, $self->type_constraint) };
}

before _process_options => sub {
    my ( $self, $name, $options ) = @_;
    $options->{required} = 1    unless ( exists $options->{required} );
    $options->{is}       = 'ro' unless ( exists $options->{is} );
    %$options = ( builder => '_build_es_id', lazy => 1, %$options )
      if ( $options->{id} && ref $options->{id} eq 'ARRAY' );
};

1;
