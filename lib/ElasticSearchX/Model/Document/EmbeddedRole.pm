package ElasticSearchX::Model::Document::EmbeddedRole;

# Mark a Document class for use as an embedded object only
# Classes which do this role will not create their own mapping
# in Elasticsearch

use Moose::Role;

1;

