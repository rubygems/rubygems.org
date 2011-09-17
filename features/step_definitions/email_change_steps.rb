Given /^I have changed my email address to "([^\"]*)"$/ do |email|
  Given %{I am on my edit profile page}
  When  %{I fill in "Email address" with "#{email}"}
  And   %{I press "Update"}
end
