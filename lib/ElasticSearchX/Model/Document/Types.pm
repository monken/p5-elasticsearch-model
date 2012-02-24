package ElasticSearchX::Model::Document::Types;
use List::MoreUtils ();
use DateTime::Format::Epoch::Unix;
use DateTime::Format::ISO8601;
use ElasticSearch;
use MooseX::Attribute::Deflator;
use MooseX::Attribute::Deflator::Moose;
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

use Sub::Exporter -setup =>
    { exports => [qw(Location QueryType ES Type Types)] };

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
            my $meta = Class::MOP::Class->initialize($_);
            $meta->short_name => $meta
            } @$array
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
my @stat
    = qw(dev ino mode nlink uid gid rdev size atime mtime ctime blksize blocks);
deflate 'File::stat', via { return { List::MoreUtils::mesh( @stat, @$_ ) } },
    inline_as {
    join( "\n",
        'my @stat = qw(dev ino mode nlink uid gid',
        'rdev size atime mtime ctime blksize blocks);',
        'List::MoreUtils::mesh( @stat, @$value )',
    );
    };
deflate [ 'ArrayRef', 'HashRef' ],
    via { shift->dynamic ? $_ : encode_json($_) }, inline_as {
    return '$value' if ( $_[0]->dynamic );
    return 'JSON::XS::encode_json($value)';
    };
inflate [ 'ArrayRef', 'HashRef' ],
    via { shift->dynamic ? $_ : decode_json($_) }, inline_as {
    return '$value' if ( $_[0]->dynamic );
    return 'JSON::XS::decode_json($value)';
    };

deflate 'ArrayRef', via {$_}, inline_as {'$value'};
inflate 'ArrayRef', via {$_}, inline_as {'$value'};

deflate 'DateTime', via { $_->iso8601 }, inline_as {'$value->iso8601'};
inflate 'DateTime', via { DateTime::Format::ISO8601->parse_datetime($_) },
    inline_as {'DateTime::Format::ISO8601->parse_datetime($value)'};
deflate Location, via { [ $_->[0] + 0, $_->[1] + 0 ] },
    inline_as {'[ $value->[0] + 0, $value->[1] + 0 ]'};
deflate Type . '[]', via { ref $_ eq 'HASH' ? $_ : $_->meta->get_data($_) },
    inline_as {
    'ref $value eq "HASH" ? $value : $value->meta->get_data($value)';
    };

no MooseX::Attribute::Deflator;

1;
