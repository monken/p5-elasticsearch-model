package ElasticSearch::Model::Tutorial;
# ABSTRACT: Tutorial for ElasticSearch::Model
1;

__END__

=head1 INTRODUCTION

In this tutorial we are going to walk through the ElasticSearch example
on L<http://www.elasticsearch.org/>. Go ahead and read it first,
this gives you a good insight into how ElasticSearch works and how
L<ElasticSearch::Model> can help to make it even more elastic.

=head1 DOCUMENTS

ElasticSearch is a document-based storage system. Even though it states
that it is schema free, it is not recommended to use ElasticSearch
without defining a proper schema or type, as ElasticSearch calls it.

L<ElasticSearch::Document> takes care of that. The ElasticSearch example
consists of two types: C<tweet> and C<user>. The C<tweet> type
contains the properties C<user>, C<post_date> and C<message>. The C<user>
type contains only the C<name> property. Using L<ElasticSearch::Document>
this looks like:

 package MyModel::Tweet;
 use Moose;
 use ElasticSearch::Document;
 
 has id => ( id => [qw(user post_date)] );
 has user => ( isa => 'Str' );
 has post_date => ( isa => 'DateTime' );
 has message => ( isa => 'Str' );
 
 package MyModel::User;
 use Moose;
 use ElasticSearch::Document;
 
 has nickname => ( isa => 'Str', id => 1 );
 has name => ( isa => 'Str' );
 
By default, all attributes defined in L<ElasticSearch::Document> classes
are required and a read-only accessor is set up. This is different from
the default Moose behaviour, but saves a lot of typing.

You might be wondering why there is an additional C<id> attribute and a
C<nickname>. The C<id> attribute in the Tweet class is build dynamically
by concatenating the values of C<user> and C<post_date>. this value is
digested using SHA1 and used as id for the document. If you want to
change the message of the tweet, you don't have to delete the old record
and add a new one but simply change the message and reindex the document.
Since the id will stay the same, the new record will overwrite the old one.
Also, you don't have to keep track of incrementing document ids.

In the User class, the C<nickname> attribute acts as id. Since it does not
depend on the value of any other attribute, the id matches the nickname.

ElasticSearch search will assign a random id to the document if there is
no id attribute.

=head1 MAPPING

Each document belongs to a type. Think of it as a table in a relational
database. And each type belongs to an index, which corresponds to a database.

Modeling indices and types with L<ElasticSearch::Model> is pretty easy
and the types have actually already been built: the meta objects of the
document classes describe the types. They include all the necessary 
information to build a type mapping.

Indices are defined in a model class:

 package MyModel;
 use Moose;
 use ElasticSearch::Model;
 
 index twitter => ( namespace => 'MyModel' );

This is all you need to define the index and its types. The namespace option
of the index C<twitter> will load all classes in the C<MyModel> namespace
and add them to the twitter index. Actually, you don't even have to define
the namespace in this case, since the namespace defaults to the name of the
mode class. You can also load types explicitly bydefining a C<types> option:

 index twitter => ( types => [MyModel::Tweet->meta, MyModel::User->meta] );

Make sure that the classes are loaded. See L<ElasticSearch::Model::Index> for all
the available options.

To deploy the indices and mappings to ElasticSearch, simply call

 my $model = MyModel->new;
 $model->deploy;

This will try to connect to an ElasticSearch instance on 127.0.0.1:9200.
See L<ElasticSearch::Model/CONSTRUCTOR> for more information.

=head1 INDEXING

 use DateTime;
 
 my $twitter = $model->index('twitter');
 $twitter->type('tweet')->put({
     user => 'mo',
     post_date => DateTime->now,
     message => 'Elastic baby!',
 }, { refresh => 1 });

 $twitter->type('tweet')->count; # 1

The second parameter to L<ElasticSearch::Document::Set/put> tells
ElasticSearch to refresh the index immediately. Otherwise it can
take up to one second for the server to refresh and the subsequent
call to L<ElasticSearch::Document::Set/count> will return C<0>.

If you index large numbers of documents, it is adviced to call
L<ElasticSearch::Model::Index/refresh> once you are finished and not
on every put.

TBD

=head1 SEARCHING

ElasticSearch is I<You know, for Search>. TBD