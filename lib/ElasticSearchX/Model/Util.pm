package ElasticSearchX::Model::Util;
use strict;
use warnings;

sub digest {
    my $digest = join( "\0", @_ );
    $digest = Digest::SHA1::sha1_base64($digest);
    $digest =~ tr/[+\/]/-_/;
    return $digest;
}

1;