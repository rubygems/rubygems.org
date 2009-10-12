# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{aws-s3}
  s.version = "0.6.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Marcel Molina Jr."]
  s.date = %q{2009-04-28}
  s.default_executable = %q{s3sh}
  s.description = %q{Client library for Amazon's Simple Storage Service's REST API}
  s.email = %q{marcel@vernix.org}
  s.executables = ["s3sh"]
  s.extra_rdoc_files = ["README", "COPYING", "INSTALL"]
  s.files = ["Rakefile", "lib/aws/s3/acl.rb", "lib/aws/s3/authentication.rb", "lib/aws/s3/base.rb", "lib/aws/s3/bittorrent.rb", "lib/aws/s3/bucket.rb", "lib/aws/s3/connection.rb", "lib/aws/s3/error.rb", "lib/aws/s3/exceptions.rb", "lib/aws/s3/extensions.rb", "lib/aws/s3/logging.rb", "lib/aws/s3/object.rb", "lib/aws/s3/owner.rb", "lib/aws/s3/parsing.rb", "lib/aws/s3/response.rb", "lib/aws/s3/service.rb", "lib/aws/s3/version.rb", "lib/aws/s3.rb", "bin/s3sh", "bin/setup.rb", "support/faster-xml-simple/lib/faster_xml_simple.rb", "support/faster-xml-simple/test/regression_test.rb", "support/faster-xml-simple/test/test_helper.rb", "support/faster-xml-simple/test/xml_simple_comparison_test.rb", "support/rdoc/code_info.rb", "README", "COPYING", "INSTALL", "test/acl_test.rb", "test/authentication_test.rb", "test/base_test.rb", "test/bucket_test.rb", "test/connection_test.rb", "test/error_test.rb", "test/extensions_test.rb", "test/fixtures/buckets.yml", "test/fixtures/errors.yml", "test/fixtures/headers.yml", "test/fixtures/logging.yml", "test/fixtures/loglines.yml", "test/fixtures/logs.yml", "test/fixtures/policies.yml", "test/fixtures.rb", "test/logging_test.rb", "test/mocks/fake_response.rb", "test/object_test.rb", "test/parsing_test.rb", "test/remote/acl_test.rb", "test/remote/bittorrent_test.rb", "test/remote/bucket_test.rb", "test/remote/logging_test.rb", "test/remote/object_test.rb", "test/remote/test_file.data", "test/remote/test_helper.rb", "test/response_test.rb", "test/service_test.rb", "test/test_helper.rb"]
  s.homepage = %q{http://amazon.rubyforge.org}
  s.rdoc_options = ["--title", "AWS::S3 -- Support for Amazon S3's REST api", "--main", "README", "--line-numbers", "--inline-source"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{amazon}
  s.rubygems_version = %q{1.3.5}
  s.summary = %q{Client library for Amazon's Simple Storage Service's REST API}
  s.test_files = ["test/acl_test.rb", "test/authentication_test.rb", "test/base_test.rb", "test/bucket_test.rb", "test/connection_test.rb", "test/error_test.rb", "test/extensions_test.rb", "test/fixtures/buckets.yml", "test/fixtures/errors.yml", "test/fixtures/headers.yml", "test/fixtures/logging.yml", "test/fixtures/loglines.yml", "test/fixtures/logs.yml", "test/fixtures/policies.yml", "test/fixtures.rb", "test/logging_test.rb", "test/mocks/fake_response.rb", "test/object_test.rb", "test/parsing_test.rb", "test/remote/acl_test.rb", "test/remote/bittorrent_test.rb", "test/remote/bucket_test.rb", "test/remote/logging_test.rb", "test/remote/object_test.rb", "test/remote/test_file.data", "test/remote/test_helper.rb", "test/response_test.rb", "test/service_test.rb", "test/test_helper.rb"]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<xml-simple>, [">= 0"])
      s.add_runtime_dependency(%q<builder>, [">= 0"])
      s.add_runtime_dependency(%q<mime-types>, [">= 0"])
    else
      s.add_dependency(%q<xml-simple>, [">= 0"])
      s.add_dependency(%q<builder>, [">= 0"])
      s.add_dependency(%q<mime-types>, [">= 0"])
    end
  else
    s.add_dependency(%q<xml-simple>, [">= 0"])
    s.add_dependency(%q<builder>, [">= 0"])
    s.add_dependency(%q<mime-types>, [">= 0"])
  end
end
