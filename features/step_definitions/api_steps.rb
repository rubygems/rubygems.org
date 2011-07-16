Given /^I have an api key for "([^\"]*)"$/ do |creds|
  user, pass = creds.split('/')
  page.driver.browser.basic_authorize(user, pass)
  get api_v1_api_key_path
  @api_key = page.body
end

Given /^I've already pushed the gem "([^\"]*)" with my api key$/ do |name| # '
  When %Q[I push the gem "#{name}" with my api key]
end

When /^I push the gem "([^\"]*)" with my api key$/ do |name|
  api_key_header
  path = File.join(TEST_DIR, name)
  post api_v1_rubygems_path, File.open(path).read
end

When 'I push an invalid .gem file' do
  api_key_header
  post api_v1_rubygems_path, 'ZZZZZZZZZZZZZZZZZZ'
end

When /^I yank the gem "([^\"]*)" version "([^\"]*)" with my api key$/ do |name, version_number|
  header("HTTP_AUTHORIZATION", @api_key)
  delete yank_api_v1_rubygems_path(:gem_name => name, :version => version_number)
  assert_match /Successfully yanked gem: #{name} \(#{version_number}\)/, page.body
end

When /^I attempt to yank the gem "([^\"]*)" version "([^\"]*)" with my api key$/ do |name, version_number|
  header("HTTP_AUTHORIZATION", @api_key)
  delete yank_api_v1_rubygems_path(:gem_name => name, :version => version_number)
end

When /^I unyank the gem "([^\"]*)" version "([^\"]*)" with my api key$/ do |name, version_number|
  header("HTTP_AUTHORIZATION", @api_key)
  put unyank_api_v1_rubygems_path(:gem_name => name, :version => version_number)
  assert_match /Successfully unyanked gem: #{name} \(#{version_number}\)/, page.body
end

When /^I migrate the gem "([^\"]*)" with my api key$/ do |name|
  rubygem = Rubygem.find_by_name!(name)
  header("HTTP_AUTHORIZATION", @api_key)
  post migrate_path(:rubygem_id => rubygem.to_param)
  token = page.body
  subdomain = rubygem.versions.latest.rubyforge_project

  WebMock.stub_request(:put, "http://#{subdomain}.rubyforge.org/migrate-#{name}.html")

  put migrate_path(:rubygem_id => rubygem.to_param)
end

When /^I list the owners of gem "([^\"]*)" with my api key$/ do |name|
  api_key_header
  get api_v1_rubygem_owners_path(:rubygem_id => name)
end

When /^I list the owners of gem "([^\"]*)" as "([^"]+)" with my api key$/ do |name, format|
  api_key_header
  get "#{api_v1_rubygem_owners_path(name)}.#{format}"
end

When /^I add the owner "([^\"]*)" to the rubygem "([^\"]*)" with my api key$/ do |owner_email, rubygem_name|
  api_key_header
  post api_v1_rubygem_owners_path(:rubygem_id => rubygem_name), :email => owner_email
end

When /^I remove the owner "([^\"]*)" from the rubygem "([^\"]*)" with my api key$/ do |owner_email, rubygem_name|
  api_key_header
  delete api_v1_rubygem_owners_path(:rubygem_id => rubygem_name), :email => owner_email
end

When /^I download the rubygem "([^\"]*)" version "([^\"]*)" (\d+) times?$/ do |rubygem_name, version_number, count|
  count.to_i.times do
    get "/gems/#{rubygem_name}-#{version_number}.gem"
  end
end

When 'I request "$url"' do |url|
  get url
end

When 'I list the gems with my api key' do
  api_key_header
  get api_v1_rubygems_path
end
