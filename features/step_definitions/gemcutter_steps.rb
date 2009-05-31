Before do
  FileUtils.mkdir(TEST_DIR)
  Dir.chdir(TEST_DIR)
end

After do
  Dir.chdir(TEST_DIR)
  FileUtils.rm_rf(TEST_DIR)
end

Given /^I have a gem "([^\"]*)" with version "([^\"]*)"$/ do |name, version|
  `jeweler #{name} --summary "Gemcutter";` unless File.exists?(name)
  `cd #{name}; echo "#{version}" > VERSION; rake gemspec build 2>&1 /dev/null;`
end

When /^I push the gem "([^\"]*)" as "([^\"]*)"$/ do |name, creds|
  path = File.join(TEST_DIR, name.split('-').first, "pkg", name)
  user, pass = creds.split('/')
  basic_auth(user, pass)
  visit rubygems_path, :post, File.open(path).read
end
