package ElasticSearch::Document::Trait::Class;
use Moose::Role;
use List::Util ();
use Carp;
use Scope::Guard;

has bulk_size => ( isa => 'Int', default => 10, is => 'rw' );
has set_class => ( is => 'ro', default => 'ElasticSearch::Document::Set' );
sub bulk_commit {
    
}

sub mapping {
    my $self = shift;
    my $props =
      { map { $_->name => $_->build_property }
        sort { $a->name cmp $b->name }
        grep { $_->is_property }
        $self->get_all_attributes };
    return { _source          => { compress => \1 },
             properties       => $props, };
}

sub short_name {
    my $self = shift;
    ( my $name = $self->name ) =~ s/^.*:://;
    return lc($name);
}

sub get_id_attribute {
    my $self = shift;
    my ( $id, $more ) =
      grep { $_->id } $self->get_all_attributes;
    croak "Cannot have more than one id field on a class" if ($more);
    return $id;
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
          map { { create => { $_->_index } } } map { $self->name->new(%$_) } @step;
        
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
            $_->is_property && ( $_->has_value($instance) || $_->is_required )
          } map {
            $self->get_attribute($_)
          } $self->get_attribute_list };
}

1;
