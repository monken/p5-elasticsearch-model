package ElasticSearchX::Model::Trait::Class;

use Moose::Role;
use List::Util ();
use Carp;

sub _handles {
    my ( $s, $p ) = @_;
    return {
        "get_$s"        => 'get',
        "get_$p"        => 'values',
        "get_${s}_list" => 'keys',
        "remove_$s"     => 'delete',
        "add_$s"        => 'set',
    };
}
my %foo = (
    analyzer  => 'analyzers',
    tokenizer => 'tokenizers',
    filter    => 'filters'
);
while ( my ( $s, $p ) = each %foo ) {
    has $p => (
        traits  => ['Hash'],
        isa     => 'HashRef',
        default => sub { {} },
        handles => _handles( $s, $p )
    );
}

has indices => (
    traits  => ['Hash'],
    isa     => 'HashRef',
    default => sub { { default => {} } },
    handles => _handles( 'index', 'indices' )
);

before add_index => sub {
    my ( $self, $name, $index ) = @_;
    $self->remove_index('default');
    if ( $index->{alias_for} && $name ne $index->{alias_for} ) {
        return $self->add_index( $index->{alias_for}, $index );
    }
};

1;
