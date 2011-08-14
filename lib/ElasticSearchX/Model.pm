package ElasticSearchX::Model;

# ABSTRACT: Extensible and flexible model for ElasticSearch based on Moose
use Moose           ();
use Moose::Exporter ();
use ElasticSearchX::Model::Index;
use ElasticSearchX::Model::Bulk;

Moose::Exporter->setup_import_methods(
        with_meta       => [qw(index analyzer tokenizer filter)],
        class_metaroles => { class => ['ElasticSearchX::Model::Trait::Class'] },
        base_class_roles => [qw(ElasticSearchX::Model::Role)], );

sub index {
    my ( $self, $name, @rest ) = @_;
    if ( !ref $name ) {
        return $self->add_index( $name, {@rest} );
    } elsif ( ref $name eq 'ARRAY' ) {
        $self->add_index( $_, {@rest} ) for (@$name);
        return;
    } else {
        my $options = $name->meta->get_index( $rest[0] );
        my $index =
          ElasticSearchX::Model::Index->new( name => $rest[0],
                                             %$options, model => $name );
        $options->{types} = $index->types;
        return $index;
    }
}

sub analyzer {
    shift->add_analyzer( shift, {@_} );
}

sub tokenizer {
    shift->add_tokenizer( shift, {@_} );
}

sub filter {
    shift->add_filter( shift, {@_} );
}

1;

__END__

=head1 SYNOPSIS

 package MyModel::Tweet;
 use Moose;
 use ElasticSearchX::Model::Document;

 has message => ( isa => 'Str' );
 has date    => ( isa => 'DateTime', default => sub { DateTime->now } );

 package MyModel;
 use Moose;
 use ElasticSearchX::Model;

 __PACKAGE__->meta->make_immutable;

  my $model = MyModel->new;
  $model->deploy;
  $model->index('default')->type('tweet')->put({
      message => 'Hello there!'
  });

=head1 DESCRIPTION

This is an ElasticSearch to Moose mapper which hides the REST api
behind object-oriented api calls. ElasticSearch types and indices
are defined using Moose classes and a flexible DSL.

Deployment statements for ElasticSearch can be build dynamically
using these classes. Results from ElasticSearch inflate automatically
to the corresponding Moose classes. Furthermore, it provides
sensible defaults.

The search API makes the tedious task of building ElasticSearch queries
a lot easier.

B<< The L<ElasticSearchX::Model::Tutorial> is probably the best place
to start! >>

=head1 DSL

=head2 index

 index twitter => ( namespace => 'MyNamespace' );

Adds an index to the model. By default there is a C<default>
index, which will be removed once you add custom indices.

See L<ElasticSearchX::Model::Index/ATTRIBUTES> for available options.

=head2 analyzer

=head2 tokenizer

=head2 filter

 analyzer lowercase => ( tokenizer => 'keyword',  filter   => 'lowercase' );

Adds analyzers, tokenizers or filters to all indices. They can
then be used in attributes of L<ElasticSearchX::Model::Document> classes.

=head1 ATTRIBUTES

=head2 es

Builds and holds the L<ElasticSearch> object. Valid values are:

=over

=item B<:9200>

Connect to a server on C<127.0.0.1>, port C<9200> with the C<httptiny>
transport class and a timeout of 30 seconds.

=item B<[qw(:9200 12.12.12.12:9200)]>

Connect to C<127.0.0.1:9200> and C<12.12.12.12:9200> with the same
defaults as above.

=item B<{ %args }>

Passes C<%args> directly to the L<ElasticSearch> constructor.

=back

=head2 bulk

Returns an instance of L<ElasticSearchX::Model::Bulk>.


=head1 METHODS

=head2 index

Returns an L<ElasticSearchX::Model::Index> object.

=head2 deploy

C<deploy> will remove all indices and then insert them one
after the other. See L</upgrade> for an upgrade routine.

If the index exists, ElasticSearch tries to update the mapping
which might fail (depending on the changes to the mapping).

To create the indices from scratch, pass C<< delete => 1 >>:

 $mode->deploy( delete => 1 );
