Factory.factories.each do |name, factory|
  Given /^an? #{name} exists with an? (.*) of "([^"]*)"$/ do |attr, value|
    Factory(name, attr.gsub(' ', '_') => value)
  end
end

Given /^a version exists for the "([^\"]*)" rubygem with a number of "([^\"]*)"$/ do |rubygem_name, version_number|
  rubygem = Rubygem.find_by_name!(rubygem_name)
  Factory(:version, :rubygem => rubygem, :number => version_number)
end

Given /^a version exists for the "([^\"]*)" rubygem with a description of "([^\"]*)"$/ do |rubygem_name, version_description|
  rubygem = Rubygem.find_by_name!(rubygem_name)
  Factory(:version, :rubygem => rubygem, :description => version_description)
end

Given /^a version exists for the "([^\"]*)" rubygem with a platform of "([^\"]*)"$/ do |rubygem_name, version_platform|
  rubygem = Rubygem.find_by_name!(rubygem_name)
  Factory(:version, :rubygem => rubygem, :platform => version_platform, :created_at => 1.hour.ago)
end

Given /^the "([^\"]*)" rubygem is owned by "([^\"]*)"/ do |rubygem_name, owner_email|
  rubygem = Rubygem.find_by_name!(rubygem_name)
  owner   = User.find_by_email(owner_email)
  Factory(:ownership, :rubygem => rubygem, :user => owner, :approved => true)
end

Given /^a subscription by "([^\"]*)" to the gem "([^\"]*)"$/ do |user_email, rubygem_name|
  rubygem = Rubygem.find_by_name!(rubygem_name)
  user    = User.find_by_email(user_email)
  Factory(:subscription, :rubygem => rubygem, :user => user)
end

Given "the following versions exist:" do |table|
  table.hashes.each do |row|
    Factory(:version, :rubygem  => Rubygem.find_by_name!(row["Rubygem"]),
                      :number   => row["Number"],
                      :platform => row["Platform"])
  end
end
