Factory.factories.each do |name, factory|
  Given /^an? #{name} exists with an? (.*) of "([^"]*)"$/ do |attr, value|
    Factory(name, attr.gsub(' ', '_') => value)
  end
end

Given /^a version exists for the "([^\"]*)" rubygem with a description of "([^\"]*)"$/ do
  |rubygem_name, version_description|
  rubygem = Rubygem.find_by_name!(rubygem_name)
  Factory(:version, :rubygem => rubygem, :description => version_description)
end

Given /^the "([^\"]*)" rubygem is owned by "([^\"]*)"/ do |rubygem_name, owner_email|
  rubygem = Rubygem.find_by_name!(rubygem_name)
  owner   = User.find_by_email(owner_email)
  Factory(:ownership, :rubygem => rubygem, :user => owner, :approved => true)
end
