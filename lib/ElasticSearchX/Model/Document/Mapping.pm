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
    } elsif ($sub) {
        return $sub->( $attr, $constraint );
    }
}

$MAPPING{Any} = sub {

    my ( $attr, $tc ) = @_;
    return ( store => $attr->store,
             $attr->index ? ( index => $attr->index ) : (),
             $attr->type eq 'object' ? ( dynamic => $attr->dynamic ) : (),
             $attr->boost ? ( boost => $attr->boost ) : (),
             !$attr->include_in_all ? ( include_in_all => \0 ) : (),
             type  => 'string',
             $attr->analyzer->[0] ? ( analyzer => $attr->analyzer->[0] ) : (), );
};

$MAPPING{Str} = sub {
    my ( $attr, $tc ) = @_;
    my %term = $attr->term_vector ? ( term_vector => $attr->term_vector ) : ();
    if ( $attr->index && $attr->index eq 'analyzed' || @{ $attr->analyzer } ) {
        my @analyzer = @{ $attr->{analyzer} };
        push(@analyzer, 'standard') unless(@analyzer);
        return (
            type   => 'multi_field',
            fields => {
                ($attr->not_analyzed ? ($attr->name => { store => $attr->store,
                                 index => 'not_analyzed',
                                 !$attr->include_in_all ? ( include_in_all => \0 ) : (),
                                 $attr->boost ? ( boost => $attr->boost ) : (),
                                 type => $attr->type,
                } ) : () ),
                analyzed => { store => $attr->store,
                           index => 'analyzed',
                           $attr->boost ? ( boost => $attr->boost ) : (),
                           type => $attr->type,
                           %term,
                           analyzer => shift @analyzer },
                (
                   map {
                       $_ => { store => $attr->store,
                               index => 'analyzed',
                               $attr->boost ? ( boost => $attr->boost ) : (),
                               type => $attr->type,
                               %term,
                               analyzer => $_ }
                     } @analyzer
                ) } );
    }
    return ( index => 'not_analyzed', %term, maptc( $attr, $tc->parent ) );
};


$MAPPING{Num} = sub {
    my ( $attr, $tc ) = @_;
    return ( maptc( $attr, $tc->parent), type => 'float' );
};


$MAPPING{Int} = sub {
    my ( $attr, $tc ) = @_;
    return ( maptc( $attr, $tc->parent), type => 'integer' );
};

$MAPPING{Bool} = sub {
    my ( $attr, $tc ) = @_;
    return ( maptc( $attr, $tc->parent), type => 'boolean' );
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
    my ($attr, $constraint) = @_;
    my %constraints = @{$constraint->type_constraints};
    my $value = {};
    while(my($k,$v) = each %constraints ) {
        $value->{$k} = { maptc($attr, $v) };
    }
    my %mapping = maptc($attr, $constraint->parent);
    delete $mapping{$_} for(qw(index boost store));
    return ( %mapping, type => 'object', dynamic => \0, properties => $value );
};

$MAPPING{'MooseX::Types::Structured::Optional[]'} = sub {
    my ($attr, $constraint) = @_;
    return maptc($attr, $constraint->type_parameter);
};

$MAPPING{'MooseX::Types::ElasticSearch::Location'} = sub {
    my ( $attr, $tc ) = @_;
    my %mapping = maptc($attr, $tc->parent);
    delete $mapping{$_} for(qw(index store));
    return ( %mapping, type => 'geo_point' );
};

$MAPPING{'ElasticSearchX::Model::Document::Types::Type[]'} = sub {
    my ($attr, $constraint) = @_;
    return ( %{$constraint->type_parameter->class->meta->mapping} );
};

$MAPPING{'DateTime'} = sub {
    my ( $attr, $tc ) = @_;
    return ( maptc( $attr, $tc->parent ), type => 'date' );
};
