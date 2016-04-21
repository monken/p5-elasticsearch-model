requires "Carp" => "0";
requires "Class::Load" => "0";
requires "DateTime" => "0";
requires "DateTime::Format::Epoch::Unix" => "0";
requires "DateTime::Format::ISO8601" => "0";
requires "Digest::SHA1" => "0";
requires "JSON" => "0";
requires "List::MoreUtils" => "0";
requires "List::Util" => "0";
requires "Module::Find" => "0";
requires "Moose" => "2.02";
requires "MooseX::Attribute::Chained" => "v1.0.1";
requires "MooseX::Attribute::Deflator" => "v2.2.0";
requires "MooseX::Types" => "0";
requires "MooseX::Types::ElasticSearch" => "v0.0.4";
requires "MooseX::Types::Structured" => "0";
requires "Scalar::Util" => "0";
requires "Search::Elasticsearch" => "1.11";
requires "Sub::Exporter" => "0";

on 'build' => sub {
  requires "Module::Build" => "0.3601";
};

on 'test' => sub {
  requires "File::Find" => "0";
  requires "File::Spec" => "0";
  requires "File::Temp" => "0";
  requires "IO::Handle" => "0";
  requires "IO::Socket::INET" => "0";
  requires "IPC::Open3" => "0";
  requires "Module::Build" => "0.3601";
  requires "MooseX::Types::Common::String" => "0";
  requires "Test::MockObject::Extends" => "0";
  requires "Test::More" => "0.88";
  requires "Test::Most" => "0";
};

on 'configure' => sub {
  requires "Module::Build" => "0.28";
};

on 'develop' => sub {
  requires "Pod::Coverage::TrustPod" => "0";
  requires "Test::Kwalitee" => "1.21";
  requires "Test::Pod" => "1.41";
  requires "Test::Pod::Coverage" => "1.08";
  requires "version" => "0.9901";
};
