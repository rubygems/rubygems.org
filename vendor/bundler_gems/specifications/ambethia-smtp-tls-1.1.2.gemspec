# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{ambethia-smtp-tls}
  s.version = "1.1.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Unknown", "Jason L Perry", "Elliot Cable"]
  s.date = %q{2009-04-02}
  s.description = %q{A gem package for the SMTP TLS code that's been floating around for years}
  s.email = %q{jasper@ambethia.com}
  s.extra_rdoc_files = ["README.rdoc"]
  s.files = ["README.rdoc", "VERSION.yml", "lib/smtp-tls.rb"]
  s.homepage = %q{http://github.com/ambethia/smtp-tls}
  s.rdoc_options = ["--inline-source", "--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.5}
  s.summary = %q{SMTP TLS (SSL) extension for Net::SMTP}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
