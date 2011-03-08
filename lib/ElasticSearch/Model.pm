package ElasticSearch::Model;
use Moose           ();
use Moose::Exporter ();
use ElasticSearch::Index;

Moose::Exporter->setup_import_methods(

    #as_is           => [qw(index analyzer tokenizer filter)],
    with_meta       => [qw(index analyzer tokenizer filter)],
    class_metaroles => {
        class => ['ElasticSearch::Model::Trait::Class'],

        #attribute => [ 'ElasticSearch::Document::Trait::Attribute',
        #               'MooseX::Attribute::Deflator::Meta::Role::Attribute'
        #]
    }, );

sub index {
    my ( $self, $name, @rest ) = @_;
    if ( ref $name ) {
        my $options = $name->meta->get_index( $rest[0] );
        return ElasticSearch::Index->new( $rest[0] => ( %$options, model => $name ) );
    } else {
        $self->add_index( $name, {@rest} );
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

