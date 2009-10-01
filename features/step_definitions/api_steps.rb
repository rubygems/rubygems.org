Given /^I have an api key for "([^\"]*)"$/ do |creds|
  user, pass = creds.split('/')
  basic_auth(user, pass)
  visit api_key_path, :get
  @api_key = response.body
end

Given /^I've already pushed the gem "([^\"]*)" with my api key$/ do |name|
  When %Q[I push the gem "#{name}" with my api key]
end

When /^I push the gem "([^\"]*)" with my api key$/ do |name|
  path = File.join(TEST_DIR, name)
  header("HTTP_AUTHORIZATION", @api_key)
  visit rubygems_path, :post, File.open(path).read
  assert_match /Successfully registered/, response.body
end

When /^I delete the gem "([^\"]*)" with my api key$/ do |arg1|
  pending
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
  header("HTTP_AUTHORIZATION", @api_key)
  visit rubygem_owners_path(:rubygem_id => name), :get
end

When /^I add the owner "([^\"]*)" to the rubygem "([^\"]*)" with my api key$/ do |owner_email, rubygem_name|
  header("HTTP_AUTHORIZATION", @api_key)
  visit rubygem_owners_path(:rubygem_id => rubygem_name), :post, :email => owner_email
end

When /^I remove the owner "([^\"]*)" from the rubygem "([^\"]*)" with my api key$/ do |owner_email, rubygem_name|
  header("HTTP_AUTHORIZATION", @api_key)
  visit rubygem_owners_path(:rubygem_id => rubygem_name), :delete, :email => owner_email
end