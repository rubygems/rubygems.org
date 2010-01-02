Given /^I have a gem "([^\"]*)" with version "([^\"]*)"$/ do |name, version|
  build_gem(name, version)
end

Given /^I have a gem "([^\"]*)" with version "([^\"]*)" and summary "([^\"]*)"$/ do |name, version, summary|
  build_gem(name, version, summary)
end

Given /^I have a gem "([^\"]*)" with version "([^\"]*)" and platform "([^\"]*)"$/ do |name, version, platform|
  build_gem(name, version, "Gemcutter", platform)
end

Given /^a rubygem exists with name "([^\"]*)" and rubyforge project "([^\"]*)"$/ do |name, rubyforge_project|
  rubygem = Factory(:rubygem, :name => name)
  Factory(:version, :rubygem => rubygem, :rubyforge_project => rubyforge_project)
end

Given /^a rubygem exists with name "([^\"]*)" and version "([^\"]*)"$/ do |name, version_number|
  rubygem = Factory(:rubygem, :name => name)
  Factory(:version, :rubygem => rubygem, :number => version_number)
end

Given /^I have a gem "([^\"]*)" with version "([^\"]*)" and homepage "([^\"]*)"$/ do |name, version, homepage|
  gemspec = new_gemspec(name, version, "Gemcutter", "ruby")
  gemspec.homepage = homepage
  build_gemspec(gemspec)
end

def build_gemspec(gemspec)
  builder = Gem::Builder.new(gemspec)
  builder.ui = Gem::SilentUI.new
  builder.build
end

def build_gem(name, version, summary = "Gemcutter", platform = "ruby")
  build_gemspec(new_gemspec(name, version, summary, platform))
end

def new_gemspec(name, version, summary, platform)
  gemspec = Gem::Specification.new do |s|
    s.name = "#{name}"
    s.platform = "#{platform}"
    s.version = "#{version}"
    s.authors = ["John Doe"]
    s.date = "#{Time.now.strftime('%Y-%m-%d')}"
    s.description = "#{summary}"
    s.email = "john.doe@example.org"
    s.files = []
    s.homepage = "http://example.org/#{name}"
    s.require_paths = ["lib"]
    s.rubygems_version = %q{1.3.5}
    s.summary = "#{summary}"
    s.test_files = []
  end

  def gemspec.validate
    "not validating on purpose"
  end

  gemspec
end
