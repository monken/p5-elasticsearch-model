package ElasticSearchX::Model::Document::Mapping;

use strict;
use warnings;
use Moose::Util::TypeConstraints;

our %MAPPING = ();

sub maptc {
    my ( $attr, $constraint ) = @_;
    $constraint ||= find_type_constraint('Str');
    ( my $name = $constraint->name ) =~ s/\[.*\]/\[\]/;
    my $sub = $MAPPING{$name};
    if ( !$sub && $constraint->has_parent ) {
        return maptc( $attr, $constraint->parent );
    }
    elsif ($sub) {
        return $sub->( $attr, $constraint );
    }
}

$MAPPING{Any} = sub {

    my ( $attr, $tc ) = @_;

    my %mapping = (
        store => $attr->store,
        $attr->index            ? ( index          => $attr->index )   : (),
        $attr->type eq 'object' ? ( dynamic        => $attr->dynamic ) : (),
        $attr->boost            ? ( boost          => $attr->boost )   : (),
        !$attr->include_in_all  ? ( include_in_all => \0 )             : (),
        type => 'string',
        $attr->analyzer->[0] ? ( analyzer => $attr->analyzer->[0] ) : (),
    );
    return _set_doc_values(%mapping);
};

$MAPPING{Str} = sub {
    my ( $attr, $tc ) = @_;
    my %term
        = $attr->term_vector ? ( term_vector => $attr->term_vector ) : ();
    if ( $attr->index && $attr->index eq 'analyzed' || @{ $attr->analyzer } )
    {
        my @analyzer = @{ $attr->{analyzer} };
        push( @analyzer, 'standard' ) unless (@analyzer);
        return _set_doc_values(
            type   => 'multi_field',
            fields => {
                (
                    $attr->not_analyzed
                    ? (
                        $attr->name => {
                            store      => $attr->store,
                            index      => 'not_analyzed',
                            doc_values => \1,
                            !$attr->include_in_all
                            ? ( include_in_all => \0 )
                            : (),
                            $attr->boost ? ( boost => $attr->boost ) : (),
                            type => $attr->type,
                        }
                        )
                    : ()
                ),
                analyzed => {
                    store => $attr->store,
                    index => 'analyzed',
                    $attr->boost ? ( boost => $attr->boost ) : (),
                    type      => $attr->type,
                    fielddata => { format => 'disabled' },
                    %term,
                    analyzer => shift @analyzer
                },
                (
                    map {
                        $_ => {
                            store => $attr->store,
                            index => 'analyzed',
                            $attr->boost ? ( boost => $attr->boost ) : (),
                            type      => $attr->type,
                            fielddata => { format => 'disabled' },
                            %term,
                            analyzer => $_
                            }
                    } @analyzer
                )
            }
        );
    }
    return _set_doc_values(
        index => 'not_analyzed',
        %term, maptc( $attr, $tc->parent )
    );
};

$MAPPING{Num} = sub {
    my ( $attr, $tc ) = @_;
    return _set_doc_values( maptc( $attr, $tc->parent ), type => 'float' );
};

$MAPPING{Int} = sub {
    my ( $attr, $tc ) = @_;
    return _set_doc_values( maptc( $attr, $tc->parent ), type => 'integer' );
};

$MAPPING{Bool} = sub {
    my ( $attr, $tc ) = @_;
    return _set_doc_values( maptc( $attr, $tc->parent ), type => 'boolean' );
};

$MAPPING{ScalarRef} = sub {
    my ( $attr, $tc ) = @_;
    return maptc( $attr, find_type_constraint('Str') );
};

$MAPPING{ArrayRef} = sub {
    my ( $attr, $tc ) = @_;
    return maptc( $attr, find_type_constraint('Str') );
};

$MAPPING{'ArrayRef[]'} = sub {
    my ( $attr, $tc ) = @_;
    my $param = $tc->type_parameter;
    return maptc( $attr, $param );
};

$MAPPING{'MooseX::Types::Structured::Dict[]'} = sub {
    my ( $attr, $constraint ) = @_;
    my %constraints = @{ $constraint->type_constraints };
    my $value       = {};
    while ( my ( $k, $v ) = each %constraints ) {
        $value->{$k} = { maptc( $attr, $v ) };
    }
    my %mapping = maptc( $attr, $constraint->parent );
    delete $mapping{$_} for (qw(index boost store));
    return (
        %mapping,
        type => $attr->type eq 'nested' ? 'nested' : 'object',
        dynamic    => \( $attr->dynamic ),
        properties => $value,
        $attr->include_in_root   ? ( include_in_root   => \1 ) : (),
        $attr->include_in_parent ? ( include_in_parent => \1 ) : (),
    );
};

$MAPPING{'MooseX::Types::Structured::Optional[]'} = sub {
    my ( $attr, $constraint ) = @_;
    return maptc( $attr, $constraint->type_parameter );
};

$MAPPING{'MooseX::Types::ElasticSearch::Location'} = sub {
    my ( $attr, $tc ) = @_;
    my %mapping = maptc( $attr, $tc->parent );
    delete $mapping{$_} for (qw(index store));
    return ( %mapping, type => 'geo_point', doc_values => \1 );
};

$MAPPING{'ElasticSearchX::Model::Document::Types::Type[]'} = sub {
    my ( $attr, $constraint ) = @_;
    return (
        %{ $constraint->type_parameter->class->meta->mapping },
        dynamic => \( $attr->dynamic ),
        $attr->include_in_root   ? ( include_in_root   => \1 ) : (),
        $attr->include_in_parent ? ( include_in_parent => \1 ) : (),
        type => $attr->type eq 'nested' ? 'nested' : 'object',
    );
};

$MAPPING{'DateTime'} = sub {
    my ( $attr, $tc ) = @_;
    return _set_doc_values(
        maptc( $attr, $tc->parent ),
        type       => 'date',
        doc_values => \1
    );
};

sub _set_doc_values {
    my %mapping = @_;

    if ( $mapping{type} eq 'string'
        && ( $mapping{index} || 'analyzed' ) eq 'analyzed' )
    {
        $mapping{fielddata} = { format => 'disabled' };
        delete $mapping{doc_values};
    }
    else {
        $mapping{doc_values} = \1;
        delete $mapping{fielddata};
    }
    return %mapping

}
