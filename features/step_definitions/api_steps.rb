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

When /^I migrate the gem "([^\"]*)" with my api key$/ do |name|
  header("HTTP_AUTHORIZATION", @api_key)
  visit rubygem_migrate_path(name), :post
  token = response.body

  rubygem = Rubygem.find_by_name!(name)
  subdomain = rubygem.versions.current.rubyforge_project

  FakeWeb.register_uri(:get,
                       "http://#{subdomain}.rubyforge.org/migrate-#{name}.html",
                       :body => token)

  visit rubygem_migrate_path(name), :put
end
