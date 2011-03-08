package ElasticSearch::Model::Role;
use Moose::Role;
use ElasticSearch;
use ElasticSearch::Index;

has es => ( is => 'rw', lazy_build => 1 );

sub _build_es {
    ElasticSearch->new( servers   => '127.0.0.1:9200',
                        transport => 'http',
                        timeout   => 30, );
}

sub deploy {
    my ($self, %params) = @_;
    foreach my $name ( $self->meta->get_index_list ) {
        my $index = $self->index($name);
        use Devel::Dwarn; DwarnN($index->deploy);
    }
}

sub request {
    my ($self, $path, $body) = @_;
    
}

1;
