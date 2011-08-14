package ElasticSearchX::Model::Document::Types;
use List::MoreUtils ();
use DateTime::Format::Epoch::Unix;
use DateTime::Format::ISO8601;
use ElasticSearch;
use MooseX::Attribute::Deflator;
use DateTime;
use JSON;
use Scalar::Util qw(blessed);
use MooseX::Types::ElasticSearch qw(:all);

use MooseX::Types -declare => [
    qw(
        Type
        Types
        )
];

use Sub::Exporter -setup => { exports => [qw(Location QueryType ES Type Types)] };

use MooseX::Types::Moose qw/Int Str ArrayRef HashRef/;
use MooseX::Types::Structured qw(Dict Tuple Optional);

class_type 'DateTime';
coerce 'DateTime', from Str, via {
    if ( $_ =~ /^\d+$/ ) {
        DateTime::Format::Epoch::Unix->parse_datetime($_);
    }
    else {
        DateTime::Format::ISO8601->parse_datetime($_);
    }
};

subtype Types, as HashRef ['Object'], where {
    !grep { $_->isa('Moose::Meta::Class') } keys %$_;
}, message {
    "Types must be either an ArrayRef of class names or a HashRef of name/class name pairs";
};

coerce Types, from HashRef ['Str'], via {
    my $hash = $_;
    return {
        map { $_ => Class::MOP::Class->initialize( $hash->{$_} ) }
            keys %$hash
    };
};

coerce Types, from ArrayRef ['Str'], via {
    my $array = $_;
    return {
        map {
            my $meta = Class::MOP::Class->initialize( $_ );
            $meta->short_name => $meta
            }
            @$array
    };
};

my $REGISTRY = Moose::Util::TypeConstraints->get_type_constraint_registry;

$REGISTRY->add_type_constraint(
    Moose::Meta::TypeConstraint::Parameterizable->new(
        name                 => Type,
        package_defined_in   => __PACKAGE__,
        parent               => find_type_constraint('Object'),
        constraint_generator => sub {
            sub {
                blessed $_
                    && $_->can('_does_elasticsearchx_model_document_role');
                }
        },
    )
);

Moose::Util::TypeConstraints::add_parameterizable_type(
    $REGISTRY->get_type_constraint(Type) );

use MooseX::Attribute::Deflator;
deflate 'Bool', via { \( $_ ? 1 : 0 ) };
inflate 'Bool', via { $_ ? 1 : 0 };
my @stat
    = qw(dev ino mode nlink uid gid rdev size atime mtime ctime blksize blocks);
deflate 'File::stat', via { return { List::MoreUtils::mesh( @stat, @$_ ) } };
deflate 'ScalarRef', via { ref $_         ? $$_ : $_ };
deflate 'HashRef',   via { shift->dynamic ? $_  : encode_json($_) };
inflate 'HashRef',   via { shift->dynamic ? $_  : decode_json($_) };
deflate 'DateTime',  via { $_->iso8601 };
inflate 'DateTime', via { DateTime::Format::ISO8601->parse_datetime($_) };
deflate Location, via { [ $_->[0] + 0, $_->[1] + 0 ] };
deflate Type . '[]', via { ref $_ eq 'HASH' ? $_ : $_->meta->get_data($_) };
deflate 'ArrayRef[]', via {
    my ( $attr, $constraint, $deflate ) = @_;
    return $_ if ( $attr->dynamic );
    $constraint = $constraint->parent
        if ( ref $constraint eq 'MooseX::Types::TypeDecorator' );
    my $value = [@$_];
    $_ = $deflate->( $_, $constraint->type_parameter ) for (@$value);
    return $deflate->( $value, $constraint->parent );
};
no MooseX::Attribute::Deflator;

1;
