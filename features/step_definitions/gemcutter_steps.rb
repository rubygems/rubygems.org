Before do
  FileUtils.mkdir(TEST_DIR)
  Dir.chdir(TEST_DIR)
end

After do
  Dir.chdir(TEST_DIR)
  FileUtils.rm_rf(TEST_DIR)
end

def build_gem(name, version, summary = "Gemcutter")
  FileUtils.rm_rf(name) if File.exists?(name)
  `jeweler #{name} --summary "#{summary}";`
  `cd #{name}; echo "#{version}" > VERSION; rake gemspec build 2>&1 /dev/null;`
end

Given /^I have a gem "([^\"]*)" with version "([^\"]*)"$/ do |name, version|
  build_gem(name, version)
end

Given /^I have a gem "([^\"]*)" with version "([^\"]*)" and summary "([^\"]*)"$/ do |name, version, summary|
  build_gem(name, version, summary)
end

When /^I visit the gem page for "([^\"]*)"$/ do |gem_name|
  When %{I go to the homepage}
  When %{I follow "list"}
  When %{I follow "#{gem_name.first}"}
  When %{I follow "#{gem_name}"}
end

When /^I push the gem "([^\"]*)" as "([^\"]*)"$/ do |name, creds|
  user, pass = creds.split('/')
  basic_auth(user, pass)
end

Given /^I have an api key for "([^\"]*)"$/ do |creds|
  user, pass = creds.split('/')
  basic_auth(user, pass)
  visit api_key_path, :get
  @api_key = response.body
end

When /^I push the gem "([^\"]*)" with my api key$/ do |name|
  path = File.join(TEST_DIR, name.split('-').first, "pkg", name)
  header("HTTP_AUTHORIZATION", @api_key)
  visit rubygems_path, :post, File.open(path).read
end

And /^I save and open the page$/ do
  save_and_open_page
end
