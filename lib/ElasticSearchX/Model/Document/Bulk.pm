package ElasticSearchX::Model::Document::Bulk;
use strict;
use warnings;
use Exporter qw(import);

our @EXPORT = qw(bulk);

$ElasticSearchX::Model::Document::Bulk::BULK = 0;
sub bulk (&) {
    my $code = shift;
    local $ElasticSearchX::Model::Document::Bulk::BULK = 1;
    $code->();
}

sub is_bulk {
    $ElasticSearchX::Model::Document::Bulk::BULK
}

sub stash {}

sub commit {}

1;