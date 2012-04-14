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
  rubygem = create(:rubygem, :name => name)
  create(:version, :rubygem => rubygem, :number => version_number)
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

Given /^the rubygem "([^\"]*)" does not exist$/ do |name|
  assert_nil Rubygem.find_by_name(name)
end

Given /^I have a gem "([^\"]*)" with version "([^\"]*)" and runtime dependency "([^\"]*)"$/ do |name, version, dep|
  gemspec = new_gemspec(name, version, 'Gem with Bad Deps', 'ruby')
  gemspec.add_runtime_dependency(dep, '= 0.0.0')
  build_gemspec(gemspec)
end

Given 'the following rubygems exist for "$email":' do |email, table|
  user = User.find_by_email! email
  table.hashes.each do |row|
    rubygem = create(:rubygem, :name => row['name'], :downloads => row['downloads'])
    version = create(:version, :rubygem => rubygem)
    row['downloads'].to_i.times { Download.incr(rubygem.name, version.full_name) }

    rubygem.ownerships.create :user => user
  end
end
