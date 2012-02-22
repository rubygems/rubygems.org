Given /^I have changed my email address to "([^\"]*)"$/ do |email|
  steps %{
    Given I am on my edit profile page
    When I fill in "Email address" with "#{email}"
    And I press "Update"
  }
end
