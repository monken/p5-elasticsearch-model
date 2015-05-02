use strict;
use warnings;

use lib qw(t/lib);

use DateTime;
use MyModel;
use Test::Most;

my $model   = MyModel->testing;
my $twitter = $model->index('twitter')->type('tweet');

ok(
    my $tweet = $twitter->put(
        {
            user    => 'mo',
            message => 'Elastic baby!',
        },
        { refresh => 1 }
    ),
    'Put ok'
);

is( $tweet->_version, 1, 'version is 1' );

ok( my $version1 = $twitter->get( $tweet->_id ), 'get fresh version 1' );

ok( $tweet->put, 'put again' );

is( $tweet->_version, 2, 'version is 2' );

throws_ok { $version1->update } qr/Conflict/;

{
    local $SIG{__WARN__} = sub {
        my $err = $_[0];
        unless ( $err =~ m{Use of uninitialized value} ) {
            warn @_;
        }
    };
    ok( $version1->update( { version => undef } ), 'unset version' );
}

throws_ok { $version1->update( { version => $version1->_version - 1 } ) }
qr/Conflict/;

ok( $version1->update( { version => $version1->_version } ),
    'set correct version' );

throws_ok { $version1->create } qr/Conflict/;

ok( my $bulk = $version1->index->bulk, 'create bulk' );

ok( $bulk->create($version1), 'bulk create already indexed doc' );

{
    local $SIG{__WARN__} = sub {
        my $err = $_[0];
        unless ( $err =~ m{Bulk error} ) {
            warn @_;
        }
    };
    my $return = $bulk->commit;
    is( $return->{errors}, 1, 'error' );
}

done_testing;
