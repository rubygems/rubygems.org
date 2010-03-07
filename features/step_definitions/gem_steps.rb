Given /^I have a gem "([^\"]*)" with version "([^\"]*)"$/ do |name, version|
  build_gem(name, version)
end

Given /^I have a gem "([^\"]*)" with version "([^\"]*)" and summary "([^\"]*)"$/ do |name, version, summary|
  build_gem(name, version, summary)
end

Given /^I have a gem "([^\"]*)" with version "([^\"]*)" and platform "([^\"]*)"$/ do |name, version, platform|
  build_gem(name, version, "Gemcutter", platform)
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

Given /^I have a bad gem "([^\"]*)" with version "([^\"]*)"$/ do |name, version|
  gemspec = new_gemspec(name, version, "Bad Gem", "ruby")
  gemspec.name = eval(name)
  build_gemspec(gemspec)
end

Given /^I have a gem "([^\"]*)" with version "([^\"]*)" and authors "([^\"]*)"$/ do |name, version, authors|
  gemspec = new_gemspec(name, version, "Bad Gem", "ruby")
  gemspec.authors = eval(authors)
  build_gemspec(gemspec)
end


Given /^the gem "([^\"]*)" with version "([^\"]*)" has been indexed$/ do |name, version|
  rubygem = Rubygem.find_by_name!(name)
  rubygem.versions.find_by_number(version).update_attribute(:indexed, true)
end

Given /^I have already yanked the gem "([^\"]*)" with version "([^\"]*)" with my api key$/ do |name, version|
  rubygem = Rubygem.find_by_name!(name)
  rubygem.versions.find_by_number(version).yank!
end

Given /^the rubygem "([^\"]*)" does not exist$/ do |name|
  assert_nil Rubygem.find_by_name(name)
end

Given /^I have a gem "([^\"]*)" with version "([^\"]*)" and runtime dependency "([^\"]*)"$/ do |name, version, dep|
  gemspec = new_gemspec(name, version, 'Gem with Bad Deps', 'ruby')
  gemspec.add_runtime_dependency(dep, '= 0.0.0')
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
    s.name = name
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
