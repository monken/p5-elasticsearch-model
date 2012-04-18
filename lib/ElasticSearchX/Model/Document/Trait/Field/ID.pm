package ElasticSearchX::Model::Document::Trait::Field::ID;
use Moose::Role;
use ElasticSearchX::Model::Document::Types qw(:all);

has id => (
    is     => 'rw',
    isa    => 'ArrayRef|Bool',
);

after install_accessors => sub {
    my $self = shift;
    return unless($self->associated_class->does_role('ElasticSearchX::Model::Document::Role'));
    $self->associated_class->_add_reverse_field_alias(
        _id => $self->name );
};

package ElasticSearchX::Model::Document::Trait::Class::ID;
use Moose::Role;

1;
