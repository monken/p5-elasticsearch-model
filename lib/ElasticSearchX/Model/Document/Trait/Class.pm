package ElasticSearchX::Model::Document::Trait::Class;
use Moose::Role;
use List::Util ();
use Carp;

has bulk_size => ( isa => 'Int', default => 10, is => 'rw' );
has set_class => ( is => 'ro', builder => '_build_set_class', lazy => 1 );
has _all_properties =>
    ( is => 'ro', lazy => 1, builder => '_build_all_properties' );

sub _build_set_class {
    my $self = shift;
    my $set  = $self->name . '::Set';
    eval { Class::MOP::load_class($set); } and return $set
        or return 'ElasticSearchX::Model::Document::Set';
}

sub bulk_commit {

}

sub mapping {
    my $self  = shift;
    my $props = {
        map { $_->name => $_->build_property }
        sort { $a->name cmp $b->name }
        grep { !$_->source_only }
        grep { !$_->parent } $self->get_all_properties
    };
    my $parent = $self->get_parent_attribute;
    return {
        _source => { compress => \1 },
        $parent ? ( _parent => { type => $parent->name } ) : (),
        dynamic    => \0,
        properties => $props,
    };
}

sub short_name {
    my $self = shift;
    ( my $name = $self->name ) =~ s/^.*:://;
    return lc($name);
}

sub get_id_attribute {
    my $self = shift;
    my ( $id, $more ) = grep { $_->id } $self->get_all_properties;
    croak "Cannot have more than one id field on a class" if ($more);
    return $id || $self->get_attribute('_id');
}

sub get_parent_attribute {
    my $self = shift;
    my ( $id, $more ) = grep { $_->parent } $self->get_all_properties;
    croak "Cannot have more than one parent field on a class" if ($more);
    return $id;
}

sub get_all_properties {
    my $self = shift;
    return @{ $self->_all_properties }
        if ( $self->is_immutable );
    return @{ $self->_build_all_properties };
}

sub _build_all_properties {
    return [
        grep { $_->does('ElasticSearchX::Model::Document::Trait::Attribute') }
            shift->get_all_attributes
    ];
}

sub put_mapping {
    my ( $self, $es ) = @_;
    $es->put_mapping( $self->mapping );
}

sub bulk_index {
    my ( $self, $es, $bulk, $force ) = @_;
    while ( @$bulk > $self->bulk_size || $force ) {
        my @step = splice( @$bulk, 0, $self->bulk_size );
        my @data = map { { create => { $_->_index } } }
            map { $self->name->new(%$_) } @step;

        $es->bulk(@data);
        undef $force unless (@$bulk);
    }
}

sub get_data {
    my ( $self, $instance ) = @_;
    return {
        map {
            my $deflate = $_->deflate($instance);
            defined $deflate ? ( $_->name => $deflate ) : ();
            } grep { $_->has_value($instance) || $_->is_required }
            $self->get_all_properties
    };
}

1;
