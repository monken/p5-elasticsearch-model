package MyModel;
use Moose;
use ElasticSearchX::Model;

index twitter => ( namespace => 'MyModel' );

__PACKAGE__->meta->make_immutable;