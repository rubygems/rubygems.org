Given /^my handle is "([^\"]*)"$/ do |handle|
  @me.update_attribute :handle, handle
end

Given /^my handle is nil$/ do
  @me.update_attribute :handle, nil
end

When /^I sign in (?:with|as) "(.*)" with "(.*)"$/ do |email, password|
  When %{I go to the sign in page}
  And %{I fill in "Email" with "#{email}"}
  And %{I fill in "Password" with "#{password}"}
  And %{I press "Sign in"}
end
