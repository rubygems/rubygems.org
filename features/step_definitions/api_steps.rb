Given /^I have an API key for "([^\"]*)"$/ do |creds|
  user, pass = creds.split('/')
  page.driver.browser.basic_authorize(user, pass)
  visit api_v1_api_key_path
  @api_key = page.source
end

When /^I push the fixture gem "([^\"]*)" with my API key$/ do |name|
  api_key_header
  path = Rails.root.join('test', 'gems', name)
  page.driver.post api_v1_rubygems_path, File.read(path), {"CONTENT_TYPE" => "application/octet-stream"}
end

When /^I GET "(.*?)"$/ do |url|
  get url
end

Then /^the JSON response should include all of the gem version metadata$/ do
  response = JSON.parse last_response.body

  version = Version.first

  version.payload.each do |attribute, value|
    assert_equal value, response.first[attribute] unless attribute == "built_at"
  end
end

Then /the returned JSON should include licenses:MIT$/ do
  response = JSON.parse last_response.body
  assert_equal 'MIT', response.first['licenses']
end

Then /the returned JSON should include licenses:GPLv2,Proprietary$/ do
  response = JSON.parse last_response.body
  assert_equal 'MIT,Proprietary', response.first['licenses']
end

Then /the returned JSON should include licenses:$/ do
  response = JSON.parse last_response.body
  assert_equal '', response.first['licenses']
end

When /^I push the gem "([^\"]*)" with my API key$/ do |name|
  api_key_header
  path = File.join(TEST_DIR, name)
  page.driver.post api_v1_rubygems_path, File.read(path), {"CONTENT_TYPE" => "application/octet-stream"}
end

When /^I push an invalid .gem file$/ do
  api_key_header
  page.driver.post api_v1_rubygems_path, 'ZZZZZZZZZZZZZZZZZZ', {"CONTENT_TYPE" => "application/octet-stream"}
end

When /^I yank the gem "([^\"]*)" version "([^\"]*)" with my API key$/ do |name, version_number|
  api_key_header
  page.driver.delete yank_api_v1_rubygems_path(:gem_name => name, :version => version_number)
  assert_match /Successfully yanked gem: #{name} \(#{version_number}\)/, page.source
end

When /^I attempt to yank the gem "([^\"]*)" version "([^\"]*)" with my API key$/ do |name, version_number|
  api_key_header
  page.driver.delete yank_api_v1_rubygems_path(:gem_name => name, :version => version_number)
end

When /^I unyank the gem "([^\"]*)" version "([^\"]*)" with my API key$/ do |name, version_number|
  api_key_header
  page.driver.put unyank_api_v1_rubygems_path(:gem_name => name, :version => version_number)
  assert_match /Successfully unyanked gem: #{name} \(#{version_number}\)/, page.source
end

When /^I list the owners of gem "([^\"]*)" with my API key$/ do |name|
  api_key_header
  visit api_v1_rubygem_owners_path(:rubygem_id => name, :format => 'json')
end

When /^I list the owners of gem "([^\"]*)" as "([^"]+)" with my API key$/ do |name, format|
  api_key_header
  visit api_v1_rubygem_owners_path(:rubygem_id => name, :format => format)
end

When /^I add the owner "([^\"]*)" to the rubygem "([^\"]*)" with my API key$/ do |owner_email, rubygem_name|
  api_key_header
  page.driver.post api_v1_rubygem_owners_path(:rubygem_id => rubygem_name), :email => owner_email
end

When /^I remove the owner "([^\"]*)" from the rubygem "([^\"]*)" with my API key$/ do |owner_email, rubygem_name|
  api_key_header
  page.driver.delete api_v1_rubygem_owners_path(:rubygem_id => rubygem_name), :email => owner_email
end

When /^I download the rubygem "([^\"]*)" version "([^\"]*)" (\d+) times?$/ do |rubygem_name, version_number, count|
  count.to_i.times do
    visit "/gems/#{rubygem_name}-#{version_number}.gem"
  end
end

When /^I list the gems for owner "([^\"]*)"$/ do |handle|
  visit api_v1_owners_gems_path(:handle => handle, :format => 'json')
end

When 'I request "$url"' do |url|
  visit url
end

When /I list the gems with my API key/ do
  api_key_header
  visit api_v1_rubygems_path(:format => 'json')
end

Then /the response should contain "([^"]+)"/ do |text|
  assert_match text, page.source
end

