use strict;
use warnings;
use lib qw(t/lib);
use MyModel;
use Test::Most;
use DateTime;

my $model   = MyModel->testing;
my $twitter = $model->index('twitter')->type('user');
ok( $twitter->refresh->put(
        {   nickname => 'mo',
            name     => 'Moritz Onken',
        }
    ),
    'Put mo ok'
);

ok( my $user = $twitter->query_type('scan')->fields( ['name'] )->first, 'get name field' );

is($user->name, 'Moritz Onken', 'got field ok');

done_testing;
