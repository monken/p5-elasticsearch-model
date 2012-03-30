use strict;
use warnings;
use lib qw(t/lib);
use MyModel;
use Test::Most;
use DateTime;

my $model   = MyModel->testing;
my $twitter = $model->index('twitter')->type('user');
ok( $twitter->put(
        {   nickname => 'mo',
            name     => 'Moritz Onken',
        },
        { refresh => 1 }
    ),
    'Put mo ok'
);

ok( my $user = $twitter->fields( ['nickname'] )->first, 'get name field' );

is($user->name, 'mo', 'got field ok');

done_testing;
