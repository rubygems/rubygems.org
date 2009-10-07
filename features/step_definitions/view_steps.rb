When /^I visit the gem page for "([^\"]*)"$/ do |gem_name|
  rubygem = Rubygem.find_by_name!(gem_name)
  visit rubygem_path(rubygem)
end

And /^I save and open the page$/ do
  save_and_open_page
end
