package ElasticSearchX::Model::Document::Trait::Class;
use Moose::Role;
use List::Util ();
use Carp;
use Scope::Guard;

has bulk_size => ( isa => 'Int', default => 10, is => 'rw' );
has set_class => ( is => 'ro', default => 'ElasticSearchX::Model::Document::Set' );

sub bulk_commit {

}

sub mapping {
    my $self = shift;
    my $props = { map { $_->name => $_->build_property }
                  sort { $a->name cmp $b->name } $self->get_all_properties };
    return { _source    => { compress => \1 },
             properties => $props, };
}

sub short_name {
    my $self = shift;
    ( my $name = $self->name ) =~ s/^.*:://;
    return lc($name);
}

sub get_id_attribute {
    my $self = shift;
    my ( $id, $more ) =
      grep { $_->id } $self->get_all_properties;
    croak "Cannot have more than one id field on a class" if ($more);
    return $id;
}

sub get_all_properties {
    grep { $_->does('ElasticSearchX::Model::Document::Trait::Attribute') }
      shift->get_all_attributes;
}

sub put_mapping {
    my ( $self, $es ) = @_;
    $es->put_mapping( $self->mapping );
}

sub bulk_index {
    my ( $self, $es, $bulk, $force ) = @_;
    while ( @$bulk > $self->bulk_size || $force ) {
        my @step = splice( @$bulk, 0, $self->bulk_size );
        my @data =
          map { { create => { $_->_index } } }
          map { $self->name->new(%$_) } @step;

        $es->bulk(@data);
        undef $force unless (@$bulk);
    }
}

sub get_data {
    my ( $self, $instance ) = @_;
    return {
        map {
                $_->name => $_->has_deflator
              ? $_->deflate($instance)
              : $_->get_value($instance)
          } grep {
            $_->has_value($instance) || $_->is_required
          } $self->get_all_properties };
}

1;
