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

Then /^I should see the version "([^\"]*)" featured$/ do |version_number|
  assert_select("h3", :text => version_number)
end

Then /^I should see the following dependencies for "([^"]*)":$/ do |full_name, table|
  data    = Marshal.load(response.body)
  version = Version.find_by_full_name!(full_name)

  table.hashes.each do |row|
    gem_hash = data.detect { |hash| hash[:name]     == version.rubygem.name &&
                                    hash[:number]   == version.number &&
                                    hash[:platform] == version.platform }

    assert gem_hash.present?

    assert gem_hash[:dependencies].any? { |dependency| dependency == [row['Name'], row['Requirements']] }
  end
end

Then /^I should not see any dependencies for "([^"]*)" version "([^"]*)"$/ do |rubygem_name, version_number|
  data = Marshal.load(response.body)
  gem_hash = data.detect { |hash| hash[:name] == rubygem_name && hash[:number] == version_number }
  assert_nil gem_hash
end
