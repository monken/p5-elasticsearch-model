package ElasticSearchX::Model::Document::Trait::Class;

# ABSTRACT: Trait that extends the meta class of a document class
use Moose::Role;
use List::Util ();
use Carp;
use Eval::Closure;

has set_class  => ( is => 'ro', builder => '_build_set_class',  lazy => 1 );
has short_name => ( is => 'ro', builder => '_build_short_name', lazy => 1 );
has _all_properties =>
    ( is => 'ro', lazy => 1, builder => '_build_all_properties' );

has _field_alias => (
    is      => 'ro',
    traits  => ['Hash'],
    isa     => 'HashRef[Str]',
    default => sub { {} },
    handles => { _add_field_alias => 'set' },
);
has _reverse_field_alias => (
    is      => 'ro',
    traits  => ['Hash'],
    isa     => 'HashRef[Str]',
    default => sub { {} },
    handles => { _add_reverse_field_alias => 'set' },
);

sub _build_set_class {
    my $self = shift;
    my $set  = $self->name . '::Set';
    eval { Class::MOP::load_class($set); } and return $set
        or return 'ElasticSearchX::Model::Document::Set';
}

sub mapping {
    my $self   = shift;
    my $props  = { map { $_->mapping } $self->get_all_properties };
    my $parent = $self->get_parent_attribute;
    return {
        _source => { compress => \1 },
        $parent ? ( _parent => { type => $parent->name } ) : (),
        dynamic    => \0,
        properties => $props,
        map { $_->type_mapping } $self->get_all_properties,
    };
}

sub _build_short_name {
    my $self = shift;
    ( my $name = $self->name ) =~ s/^.*:://;
    return lc($name);
}

sub get_id_attribute {
    my $self = shift;
    my (@id)
        = grep { $_->does('ElasticSearchX::Model::Document::Trait::Field::ID') }
        $self->get_all_properties;
    return pop @id;
}

sub get_parent_attribute {
    my $self = shift;
    my ( $id, $more ) = grep { $_->parent } $self->get_all_properties;
    croak "Cannot have more than one parent field on a class" if ($more);
    return $id;
}

sub get_version_attribute {
    shift->get_attribute('_version');
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

sub get_data {
    my ( $self, $instance ) = @_;
    return {
        map {
            my $deflate
                = $_->is_inflated($instance)
                || $_->is_required && !$_->has_value($instance)
                ? $_->deflate($instance)
                : $_->get_raw_value($instance);
            defined $deflate ? ( $_->field_name => $deflate ) : ();
            } grep { $_->has_value($instance) || $_->is_required }
            grep { $_->property } $self->get_all_properties
    };
}

sub get_query_data {
    my ( $self, $instance ) = @_;
    return {
        map {
            my $deflate
                = $_->is_inflated($instance)
                || $_->is_required && !$_->has_value($instance)
                ? $_->deflate($instance)
                : $_->get_raw_value($instance);
            ( my $field = $_->field_name ) =~ s/^_//;
            defined $deflate ? ( $field => $deflate ) : ();
            } grep { $_->has_value($instance) || $_->is_required }
            grep { $_->query_property } $self->get_all_properties
    };
}

sub inflate_result {
    my ( $self, $index, $res ) = @_;

    #my $id     = $self->get_id_attribute;
    my $parent = $self->get_parent_attribute;
    my $fields = { %{ $res->{_source} || {} }, %{ $res->{fields} || {} } };
    my $map    = $self->_reverse_field_alias;
    map {
        $fields->{ $map->{$_} }
            = defined $res->{$_}
            ? $res->{$_}
            : $fields->{$_}
        }
        grep { defined $fields->{$_} || defined $res->{$_} } keys %$map;
    return $self->name->new(
        {   %$fields,
            index    => $index,
            _id      => $res->{_id},
            _version => $res->{_version},
            $parent ? ( $parent->name => $res->{_parent} ) : (),
        }
    );
}

1;

=head1 ATTRIBUTES

=head2 set_class

A call to C<< $index->type('tweet') >> returns an instance of C<set_class>. Given a
document class C<MyModel::Tweet>, the builder of this attribute tries to find a
class named C<MyModel::Tweet::Set>. If it's not found, the default class
L<ElasticSearchX::Model::Document::Set> is used.

A custum set class (e.g. C<MyModel::Tweet::Set>) B<must> inherit from
L<ElasticSearchX::Model::Document::Set>.

=head2 short_name

 MyClass::Tweet->meta->short_name; # tweet

The C<short_name> is used as name for the type. It defaults to the lowercased,
last segment of the class name.

=head1 METHODS

=head2 mapping

  my $mapping = $document->meta->mapping;

Builds the type mapping for this document class. It loads all properties
using L</get_all_properties> and calls
L<ElasticSearchX::Model::Document::Trait::Attribute/build_property>.

=head2 get_id_attribute

Get the C<id> attribute, i.e. the attribute that has the C<id> option
set. Returns undef if it doesn't exist.

=head2 get_parent_attribute

Get the C<parent> attribute, i.e. the attribute that has the C<parent> option
set. Returns undef if it doesn't exist.

=head2 get_all_properties

Returns a list of all properties in the document class. An attribute is considered
a property, if it I<does> the L<ElasticSearchX::Model::Document::Trait::Attribute>
role. That means all attributes that don't have the C<property> option explicitly
set to C<0>.

Since this method is called quite often, the result is cached if the document class
is immutable.

=head2 get_data

L<ElasticSearchX::Model::Document/put> calls this method to get an HashRef of
all properties and their values. Values are deflated if a deflator was specified
(e.g. L<DateTime> objects are deflated to an ISO8601 string).
