package ElasticSearch::Document::Types;
use List::MoreUtils ();
use DateTime::Format::Epoch::Unix;
use DateTime::Format::ISO8601;
use ElasticSearch;

use MooseX::Types -declare => [
    qw(
      Location
      ESDateTime
      QueryType
      ) ];

use MooseX::Types::Moose qw/Int Str ArrayRef HashRef/;


enum QueryType, qw(query_and_fetch query_then_fetch dfs_query_and_fetch dfs_query_then_fetch);

class_type ESDateTime, { class => 'DateTime' };

coerce ESDateTime, from Str, via {
    if ( $_ =~ /^\d+$/ ) {
        DateTime::Format::Epoch::Unix->parse_datetime($_);
    } else {
        DateTime::Format::ISO8601->parse_datetime($_);
    }
};


subtype Location,
  as ArrayRef,
  where { @$_ == 2 },
  message { "Location is an arrayref of longitude and latitude" };

coerce Location, from HashRef,
  via { [ $_->{lon} || $_->{longitude}, $_->{lat} || $_->{latitude} ] };
coerce Location, from Str, via { [ reverse split(/,/) ] };

use MooseX::Attribute::Deflator;
deflate 'Bool', via { \$_ };
my @stat =
  qw(dev ino mode nlink uid gid rdev size atime mtime ctime blksize blocks);
deflate 'File::stat', via { return { List::MoreUtils::mesh( @stat, @$_ ) } };
deflate 'ScalarRef', via { $$_ };
deflate 'DateTime', via { $_->iso8601 };
deflate ESDateTime, via { $_->iso8601 };
deflate Location, via { [ $_->[0] + 0, $_->[1] + 0 ] };
no MooseX::Attribute::Deflator;

1;
