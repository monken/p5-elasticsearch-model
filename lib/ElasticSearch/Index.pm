package ElasticSearch::Index;
use Moose;
use ElasticSearch::Search;
use Module::Find ();

has name => ( is => 'ro' );

has path => ( is => 'ro' );

has namespace => ( is => 'ro', lazy_build => 1 );

has model => ( is => 'ro', required => 1 );

has traits => ( isa => 'ArrayRef', is => 'ro', default => sub {[]} );

has types => ( isa        => 'HashRef',
               traits     => ['Hash'],
               is         => 'ro',
               lazy_build => 1,
               handles    => {
                            get_types     => 'values',
                            get_type_list => 'keys',
                            add_type      => 'set',
                            remove_type   => 'delete',
                            get_type      => 'get',
               } );

sub _build_types {
    my $self      = shift;
    my $namespace = $self->namespace;
    my %stash     = Class::MOP::get_all_metaclasses;
    my @found = ( Module::Find::findallmod($namespace),
                  grep { /^\Q$namespace\E::/ } keys %stash );
    map { Class::MOP::load_class($_) } @found;
    @found = grep { $_->isa('Moose::Object') } @found;
    return { map { $_->meta->short_name => $_->meta } @found };
}

sub BUILD {
    my $self = shift;
    foreach my $trait (@{$self->traits}) {
        Moose::Util::ensure_all_roles($self, $trait);
    }
    return $self;
}

sub _build_namespace {
    ref shift->model;
}

sub search {
    return ElasticSearch::Search->new( index => shift );
}

sub deploy {
    my $self   = shift;
    my $deploy = {};
    foreach my $type ( $self->get_types ) {
        $deploy->{mappings}->{ $type->short_name } = $type->mapping;
    }
    my $model = $self->model->meta;
    for (qw(filter analyzer tokenizer)) {
        my $method = "get_${_}_list";
        foreach my $name ( $model->$method ) {
            my $get = "get_$_";
            $deploy->{analysis}->{$_}->{$name} = $model->$get($name);
        }
    }

    return $deploy;
}

__PACKAGE__->meta->make_immutable( inline_constructor => 0 );

__END__

=head1 ATTRIBUTES

=head2 namespace

Types are loaded from this namespace if the y are not explicitly 
defined using L</types>. The namespace defaults to the package
name of the model.

=head2 types

An arrayref of L<ElasticSearch::Document> meta objects.

=head2 traits

An arrayref of traits which are applied to the index object.
This is useful if you want to alter the behaviour of methods
like L</deploy>.

=head1 METHODS

=head2 deploy

This methods generates the deployment statement and deploys 
it to the ElasticSearch server.