Then /^I should not see my gravatar$/ do
  assert_have_no_selector('#user_gravatar')
end

Then /^I should see my gravatar$/ do
  assert_have_selector('#user_gravatar')
end

