package ElasticSearchX::Model::Document::Types;
use List::MoreUtils ();
use DateTime::Format::Epoch::Unix;
use DateTime::Format::ISO8601;
use ElasticSearch;
use MooseX::Attribute::Deflator;
use DateTime;
use Scalar::Util qw(blessed);

use MooseX::Types -declare => [
    qw(
      Location
      QueryType
      ES
      Type
      ) ];

use MooseX::Types::Moose qw/Int Str ArrayRef HashRef/;
use MooseX::Types::Structured qw(Dict Tuple Optional);

coerce ArrayRef, from Str, via { [$_] };

class_type ES, { class => 'ElasticSearch' };
coerce ES, from Str, via {
    my $server = $_;
    $server = "127.0.0.1$server" if ( $server =~ /^:/ );
    return
      ElasticSearch->new( servers   => $server,
                          transport => 'http',
                          timeout   => 30, );
};

coerce ES, from HashRef, via {
    return ElasticSearch->new(%$_);
};

coerce ES, from ArrayRef, via {
    my @servers = @$_;
    @servers = map { /^:/ ? "127.0.0.1$_" : $_ } @servers;
    return
      ElasticSearch->new( servers   => \@servers,
                          transport => 'http',
                          timeout   => 30, );
};

enum QueryType, qw(query_and_fetch query_then_fetch dfs_query_and_fetch dfs_query_then_fetch);

class_type 'DateTime';
coerce 'DateTime', from Str, via {
    if ( $_ =~ /^\d+$/ ) {
        DateTime::Format::Epoch::Unix->parse_datetime($_);
    } else {
        DateTime::Format::ISO8601->parse_datetime($_);
    }
};

my $REGISTRY = Moose::Util::TypeConstraints->get_type_constraint_registry;

$REGISTRY->add_type_constraint(
    Moose::Meta::TypeConstraint::Parameterizable->new(
        name               => Type,
        package_defined_in => __PACKAGE__,
        parent             => find_type_constraint('Object'),
        constraint_generator => sub { sub { blessed $_ && $_->isa('Moose::Object') && $_->does('ElasticSearchX::Model::Document::Role') } },
    )
);

Moose::Util::TypeConstraints::add_parameterizable_type($REGISTRY->get_type_constraint(Type));


subtype Location,
  as ArrayRef,
  where { @$_ == 2 },
  message { "Location is an arrayref of longitude and latitude" };

coerce Location, from HashRef,
  via { [ $_->{lon} || $_->{longitude}, $_->{lat} || $_->{latitude} ] };
coerce Location, from Str, via { [ reverse split(/,/) ] };

use MooseX::Attribute::Deflator;
deflate 'Bool', via { \($_ ? 1 : 0) };
my @stat =
  qw(dev ino mode nlink uid gid rdev size atime mtime ctime blksize blocks);
deflate 'File::stat', via { return { List::MoreUtils::mesh( @stat, @$_ ) } };
deflate 'ScalarRef', via { ref $_ ? $$_ : $_ };
deflate 'DateTime', via { $_->iso8601 };
inflate 'DateTime', via { DateTime::Format::ISO8601->parse_datetime( $_ ) };
deflate Location, via { [ $_->[0] + 0, $_->[1] + 0 ] };
deflate Type . '[]', via { ref $_ eq 'HASH' ? $_ : $_->meta->get_data($_) };
deflate 'ArrayRef[]', via {
    my ($attr, $constraint, $deflate) = @_;
    $constraint = $constraint->parent
        if(ref $constraint eq 'MooseX::Types::TypeDecorator');
    my $value = [@$_];
    $_ = $deflate->($_, $constraint->type_parameter) for(@$value);
    return $deflate->($value, $constraint->parent);
};
no MooseX::Attribute::Deflator;



1;
