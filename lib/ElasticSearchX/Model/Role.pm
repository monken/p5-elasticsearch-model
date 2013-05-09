package ElasticSearchX::Model::Role;
use Moose::Role;
use ElasticSearch;
use ElasticSearchX::Model::Index;
use version;
use ElasticSearchX::Model::Document::Types qw(ES);

has es => ( is => 'rw', lazy_build => 1, coerce => 1, isa => ES );

sub _build_es {
    ElasticSearch->new(
        servers   => '127.0.0.1:9200',
        transport => 'http',
        timeout   => 30,
    );
}

sub deploy {
    my ( $self, %params ) = @_;
    my $t = $self->es->transport;
    foreach my $name ( $self->meta->get_index_list ) {
        my $index = $self->index($name);
        next if ( $index->alias_for && $name eq $index->alias_for );
        $name = $index->alias_for if ( $index->alias_for );
        local $@;
        eval {
            $t->request( { method => 'DELETE', cmd => "/$name" } )
        } if ( $params{delete} );
        my $dep     = $index->deployment_statement;
        my $mapping = delete $dep->{mappings};
        eval {
            $t->request(
                {   method => 'PUT',
                    cmd    => "/$name",
                    data   => $dep,
                }
            );
        };
        sleep(1);
        while ( my ( $k, $v ) = each %$mapping ) {
            $t->request(
                {   method => 'PUT',
                    cmd    => "/$name/$k/_mapping",
                    data   => { $k => $v },
                }
            );
        }
        if ( my $alias = $index->alias_for ) {
            my @aliases
                = keys %{ $self->es->get_aliases( index => $index->name, ignore_missing => 1 )
                    || {} };
            my $actions = [
                (   map {
                        { remove => { index => $_, alias => $index->name } }
                        } @aliases
                ),
                { add => { index => $alias, alias => $index->name } }
            ];
            $self->es->aliases( actions => $actions );
        }
    }
    return 1;
}

sub bulk {
    my $self = shift;
    return ElasticSearchX::Model::Bulk->new( es => $self->es, @_ );
}

sub es_version {
    my $self = shift;
    my $string = $self->es->current_server_version->{number};
    $string =~ s/RC//g;
    return version->parse( $string )->numify;
}

1;
