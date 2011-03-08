package ElasticSearch::Model;
use Moose           ();
use Moose::Exporter ();
use ElasticSearch::Index;

my (undef, undef, $init_meta) =
  Moose::Exporter->build_import_methods(
         with_meta       => [qw(index analyzer tokenizer filter)],
         install         => [qw(import unimport)],
         class_metaroles => { class => ['ElasticSearch::Model::Trait::Class'] },
  );

sub init_meta {
    my $class = shift;
    my %p = @_;
    Moose::Util::ensure_all_roles( $p{for_class}, qw(ElasticSearch::Model::Role) );
    $class->$init_meta(%p);
}

sub index {
    my ( $self, $name, @rest ) = @_;
    if ( ref $name ) {
        my $options = $name->meta->get_index( $rest[0] );
        my $index = ElasticSearch::Index->new( name => $rest[0], %$options, model => $name );
        $options->{types} = $index->types;
        return $index;
    } else {
        return $self->add_index( $name, {@rest} );
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

 package MyModel::User;
 use Moose;
 use ElasticSearch::Document;

 package MyModel::Tweet;
 use Moose;
 use ElasticSearch::Document;

 has message => ( isa => 'Str' );
 has date => ( isa => 'DateTime' );

 package MyModel;
 use Moose;
 use ElasticSearch::Model;

 __PACKAGE__->meta->make_immutable;

  my $model = MyModel->new;
  $model->deploy;
  $model->index('default')->type('tweet')->put({
      message => 'Hello there!',
      date => DateTime->now,
  });

=head1 DSL

=head2 index

 index twitter => ( namespace => 'MyNamespace' );

Adds an index to the model. By default there is a C<default>
index, which will be removed once you add custom indices.

See L<ElasticSearch::Index/ATTRIBUTES> for available options.

=head2 analyzer

=head2 tokenizer

=head2 filter

 analyzer lowercase => ( tokenizer => 'keyword',  filter   => 'lowercase' );

Adds analyzers, tokenizers or filters to all indices. They can
then be used in L<ElasticSearch::Document> classes.

=head1 METHODS

=head2 index

Returns a L<ElasticSearch::Index> object.

=head2 deploy

C<deploy> will remove all indices and then insert them one
after the other. See L</upgrade> for an upgrade routine.

B<< All data will be lost during C<deploy> >>

=head2 upgrade

C<upgrade> will try add non-existing indices and update the
mapping on existing indices. Depending on the changes to
the mapping this might or might not succeed.