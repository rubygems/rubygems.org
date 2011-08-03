# General

Then /^I should see error messages$/ do
  assert_match /error(s)? prohibited/m, page.body
end

# Database

Given /^I signed up with "(.*)\/(.*)"$/ do |email, password|
  @me = user = Factory(:user,
    :email                 => email,
    :password              => password,
    :password_confirmation => password)
end

Given /^I am signed up and confirmed as "(.*)\/(.*)"$/ do |email, password|
  @me = user = Factory(:email_confirmed_user,
    :email                 => email,
    :password              => password,
    :password_confirmation => password)
end

Given /^my handle is "([^\"]*)"$/ do |handle|
  @me.update_attribute :handle, handle
end

Given /^my handle is nil$/ do
  @me.update_attribute :handle, nil
end

# Session

Then /^I should be signed in$/ do
  Then %{I should see "sign out"}
end

Then /^I should be signed out$/ do
  Then %{I should see "sign in"}
end

Given /^I have signed in with "(.*)\/(.*)"$/ do |email, password|
  Given %{I am signed up and confirmed as "#{email}/#{password}"}
  And %{I sign in as "#{email}/#{password}"}
end

# Emails

Then /^a confirmation message should be sent to "(.*)"$/ do |email|
  user = User.find_by_email(email)
  sent = ActionMailer::Base.deliveries.last
  assert_equal [user.email], sent.to
  assert_match /confirm/i, sent.subject
  assert !user.confirmation_token.blank?
  assert_match /#{user.confirmation_token}/, sent.body.to_s
end

When /^I follow the confirmation link sent to "(.*)"$/ do |email|
  user = User.find_by_email(email)
  visit new_user_confirmation_path(:user_id => user,
                                   :token   => user.confirmation_token)
end

Then /^a password reset message should be sent to "(.*)"$/ do |email|
  user = User.find_by_email(email)
  sent = ActionMailer::Base.deliveries.last
  assert_equal [user.email], sent.to
  assert_match /password/i, sent.subject
  assert !user.confirmation_token.blank?
  assert_match /#{user.confirmation_token}/, sent.body.to_s
end

When /^I follow the password reset link sent to "(.*)"$/ do |email|
  user = User.find_by_email(email)
  visit edit_user_password_path(:user_id => user,
                                :token   => user.confirmation_token)
end

When /^I try to change the password of "(.*)" without token$/ do |email|
  user = User.find_by_email(email)
  visit edit_user_password_path(:user_id => user)
end

Then /^I should be forbidden$/ do
  assert_response :forbidden
end

# Actions

When /^I sign in as "(.*)\/(.*)"$/ do |email, password|
  When %{I go to the sign in page}
  And %{I fill in "Email" with "#{email}"}
  And %{I fill in "Password" with "#{password}"}
  And %{I press "Sign in"}
end

When /^I sign out$/ do
  When %{I follow "sign out"}
end

When /^I request password reset link to be sent to "(.*)"$/ do |email|
  When %{I go to the password reset request page}
  And %{I fill in "Email address" with "#{email}"}
  And %{I press "Reset password"}
end

When /^I update my password with "(.*)\/(.*)"$/ do |password, confirmation|
  And %{I fill in "Password" with "#{password}"}
  And %{I fill in "Confirm password" with "#{confirmation}"}
  And %{I press "Save this password"}
end

When /^I return next time$/ do
  reset!
  And %{I go to the homepage}
end
