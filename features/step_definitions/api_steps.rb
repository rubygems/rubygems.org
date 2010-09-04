Given /^I have an api key for "([^\"]*)"$/ do |creds|
  user, pass = creds.split('/')
  basic_auth(user, pass)
  visit api_v1_api_key_path, :get
  @api_key = response.body
end

Given /^I've already pushed the gem "([^\"]*)" with my api key$/ do |name| # '
  When %Q[I push the gem "#{name}" with my api key]
end

def push_gem(name)
  api_key_header

  path = File.join(TEST_DIR, name)
  visit api_v1_rubygems_path, :post, File.open(path).read
end

When /^I push the gem "([^\"]*)" with my api key$/ do |name|
  push_gem(name)
end

When /^I push the gem '(.*)' with my api key$/ do |name|
  push_gem(name)
end

When 'I push an invalid .gem file' do
  api_key_header
  visit api_v1_rubygems_path, :post, 'ZZZZZZZZZZZZZZZZZZ'
end

When /^I yank the gem "([^\"]*)" version "([^\"]*)" with my api key$/ do |name, version_number|
  header("HTTP_AUTHORIZATION", @api_key)
  visit yank_api_v1_rubygems_path(:gem_name => name, :version => version_number), :delete
  assert_match /Successfully yanked gem: #{name} \(#{version_number}\)/, response.body
end

When /^I attempt to yank the gem "([^\"]*)" version "([^\"]*)" with my api key$/ do |name, version_number|
  header("HTTP_AUTHORIZATION", @api_key)
  visit yank_api_v1_rubygems_path(:gem_name => name, :version => version_number), :delete
end

When /^I unyank the gem "([^\"]*)" version "([^\"]*)" with my api key$/ do |name, version_number|
  header("HTTP_AUTHORIZATION", @api_key)
  visit unyank_api_v1_rubygems_path(:gem_name => name, :version => version_number), :put
  assert_match /Successfully unyanked gem: #{name} \(#{version_number}\)/, response.body
end

When /^I migrate the gem "([^\"]*)" with my api key$/ do |name|
  rubygem = Rubygem.find_by_name!(name)

  header("HTTP_AUTHORIZATION", @api_key)
  visit migrate_path(:rubygem_id => rubygem.to_param), :post
  token = response.body

  subdomain = rubygem.versions.latest.rubyforge_project

  FakeWeb.register_uri(:get,
                       "http://#{subdomain}.rubyforge.org/migrate-#{name}.html",
                       :body => token)

  visit migrate_path(:rubygem_id => rubygem.to_param), :put
end

When /^I list the owners of gem "([^\"]*)" with my api key$/ do |name|
  api_key_header
  visit api_v1_rubygem_owners_path(:rubygem_id => name), :get
end

When /^I add the owner "([^\"]*)" to the rubygem "([^\"]*)" with my api key$/ do |owner_email, rubygem_name|
  api_key_header
  visit api_v1_rubygem_owners_path(:rubygem_id => rubygem_name), :post, :email => owner_email
end

When /^I remove the owner "([^\"]*)" from the rubygem "([^\"]*)" with my api key$/ do |owner_email, rubygem_name|
  api_key_header
  visit api_v1_rubygem_owners_path(:rubygem_id => rubygem_name), :delete, :email => owner_email
end

When /^I download the rubygem "([^\"]*)" version "([^\"]*)" (\d+) times?$/ do |rubygem_name, version_number, count|
  count.to_i.times do
    visit "/gems/#{rubygem_name}-#{version_number}.gem", :get
  end
end

When 'I request "$url"' do |url|
  visit url
end
