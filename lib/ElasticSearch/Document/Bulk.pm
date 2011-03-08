package ElasticSearch::Document::Bulk;
use strict;
use warnings;
use Exporter qw(import);

our @EXPORT = qw(bulk);

$ElasticSearch::Document::Bulk::BULK = 0;
sub bulk (&) {
    my $code = shift;
    local $ElasticSearch::Document::Bulk::BULK = 1;
    $code->();
}

sub is_bulk {
    $ElasticSearch::Document::Bulk::BULK
}

sub stash {}

sub commit {}

1;