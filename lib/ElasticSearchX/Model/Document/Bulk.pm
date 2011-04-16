package ElasticSearchX::Model::Document::Bulk;
use Moose;
use MooseX::ClassAttributes;
use Exporter qw(import);
our @EXPORT = qw(bulk);

has stash => ( traits => ['Array'], handles => {  } );

$ElasticSearchX::Model::Document::Bulk::BULK = 0;
sub bulk (&) {
    my $code = shift;
    local $ElasticSearchX::Model::Document::Bulk::BULK = 1;
    $code->();
}

sub is_bulk {
    $ElasticSearchX::Model::Document::Bulk::BULK
}

sub commit {}

1;