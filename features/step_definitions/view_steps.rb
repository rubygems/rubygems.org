When /^I visit the gem page for "([^\"]*)"$/ do |gem_name|
  rubygem = Rubygem.find_by_name!(gem_name)
  visit rubygem_path(rubygem)
end

When /^I visit the gem page for "([^\"]*)" version "([^\"]*)"$/ do |gem_name, version_number|
  rubygem = Rubygem.find_by_name!(gem_name)
  visit rubygem_version_path(rubygem, version_number)
end

And /^I save and open the page$/ do
  save_and_open_page
end
