When /^I visit the gem page for "([^\"]*)"$/ do |gem_name|
  rubygem = Rubygem.find_by_name!(gem_name)
  get rubygem_path(rubygem)
end

When /^I visit the gem page for "([^\"]*)" version "([^\"]*)"$/ do |gem_name, version_number|
  rubygem = Rubygem.find_by_name!(gem_name)
  get rubygem_version_path(rubygem, version_number)
end

And /^I save and open the page$/ do
  save_and_open_page
  print page.body
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
  version = Version.find_by_full_name!(full_name)

  table.hashes.each do |row|
    gem_hash = marshal_body.detect { |hash| hash[:name]     == version.rubygem.name &&
                                            hash[:number]   == version.number &&
                                            hash[:platform] == version.platform }

    assert gem_hash.present?

    assert gem_hash[:dependencies].any? { |dependency| dependency == [row['Name'], row['Requirements']] }
  end
end

Then /^I should not see any dependencies for "([^"]*)" version "([^"]*)"$/ do |rubygem_name, version_number|
  gem_hash = marshal_body.detect { |hash| hash[:name] == rubygem_name && hash[:number] == version_number }
  assert_nil gem_hash
end

Then "I should see an empty array" do
  assert marshal_body.is_a?(Array)
  assert marshal_body.empty?
end

Then /^I should see only (\d+) element in the array$/ do |count|
  assert_equal count.to_i, marshal_body.size
end

Then /I (should|should not) see download graphs for the following rubygems:/ do |should, table|
  table.raw.flatten.each do |name|
    rubygem = Rubygem.find_by_name!(name)
    meth = should == "should not" ? :assert_have_no_selector : :assert_have_selector
    send meth, "#graph-#{rubygem.id}"

    within(".profile-rubygem") do
      assert_contain rubygem.name
    end

    within(".profile-downloads") do
      assert_contain "#{rubygem.downloads} downloads"
    end
  end
end
