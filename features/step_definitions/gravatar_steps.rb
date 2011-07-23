Then /^I should not see my gravatar$/ do
  assert ! page.has_css?("#user_gravatar")
end

Then /^I should see my gravatar$/ do
  assert page.has_css?("#user_gravatar")
end

