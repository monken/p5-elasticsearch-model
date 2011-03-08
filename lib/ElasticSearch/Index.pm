package ElasticSearch::Index;
use Moose;
extends 'Moose::Meta::Attribute';
use ElasticSearch::Search;
use Module::Find ();

has namespace => ( is => 'ro', lazy_build => 1 );

has model => ( is => 'ro', required => 1 );

has types => ( isa        => 'HashRef',
               traits     => ['Hash'],
               is => 'ro',
               lazy_build => 1,
               handles    => {
                            get_types     => 'values',
                            get_type_list => 'keys',
                            add_type      => 'set',
                            remove_type   => 'delete',
                            get_type      => 'get',
               } );

sub _build_types {
        my $self = shift;
        my $namespace = $self->namespace;
        my %stash = Class::MOP::get_all_metaclasses;
        my @found = (Module::Find::findallmod($namespace), grep { /^\Q$namespace\E::/} keys %stash);
        map { Class::MOP::load_class($_) } @found;
        @found = grep { $_->isa('Moose::Object') } @found;
        return { map { $_->meta->short_name  => $_->meta } @found };
    
}

sub _build_namespace {
    ref shift->model;
}

sub search {
    return ElasticSearch::Search->new( index => shift );
}

__PACKAGE__->meta->make_immutable( inline_constructor => 0 );
