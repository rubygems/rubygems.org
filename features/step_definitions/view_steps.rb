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

Then /^I should see the following most recent downloads:$/ do |table|
  count = 0
  table.hashes.each do |row|
    assert_select "#most_downloaded li:nth-child(#{count += 1})",
                  "#{row['name']} (#{row['downloads']})"
  end
end
