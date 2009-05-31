Before do
  FileUtils.mkdir(TEST_DIR)
  Dir.chdir(TEST_DIR)
end

After do
  Dir.chdir(TEST_DIR)
  FileUtils.rm_rf(TEST_DIR)
end

Given /^I have a gem "([^\"]*)" with version "([^\"]*)"$/ do |name, version|
  `jeweler #{name} --summary "Gemcutter"; cd #{name}; echo "#{version}" > VERSION; rake gemspec build 2>&1 /dev/null;`
  Dir.chdir(File.join(TEST_DIR, name, "pkg"))
end

When /^I push the gem "([^\"]*)" as "([^\"]*)"$/ do |name, creds|
  user, pass = creds.split('/')
  basic_auth(user, pass)
  visit rubygems_path, :post, File.open(name).read
end

When /^I visit the gem page for "([^\"]*)"$/ do |name|
  rubygem = Rubygem.find_by_name(name)
  visit rubygem_path(rubygem)
end

Given /^I own a gem "([^\"]*)" with version "([^\"]*)"$/ do |name, version|
  pending
end

Given /^the gem "([^\"]*)" exists with version "([^\"]*)"$/ do |name, version|
  pending
end

