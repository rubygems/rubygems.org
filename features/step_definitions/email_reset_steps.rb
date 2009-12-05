Then /^an email entitled "([^\"]*)" should be sent to "([^\"]*)"$/ do |subject, email|
  sent = ActionMailer::Base.deliveries.first
  assert_equal [email], sent.to
  assert_match subject, sent.subject
end

Given /^I have reset my email address to "([^\"]*)"$/ do |email|
  pending
end

Then /^I should see the message "([^\"]*)"$/ do |message|
  pending
end
