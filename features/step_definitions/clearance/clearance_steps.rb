# General

Then /^I should see error messages$/ do
  Then %{I should see "errors prohibited"}
end

Then /^I should see an error message$/ do
  Then %{I should see "error prohibited"}
end

Then /^I should see an email field$/ do
  if page.respond_to?(:should)
    page.should have_css?("input[type='email']")
  else
    assert page.has_css?("input[type='email']")
  end
end

# Database

Given /^no user exists with an email of "(.*)"$/ do |email|
  assert_nil User.find_by_email(email)
end

Given /^(?:I am|I have|I) signed up (?:as|with) "(.*)"$/ do |email|
  @me = Factory(:user, :email => email)
end

Given /^a user "([^"]*)" exists without a salt, remember token, or password$/ do |email|
  @me = user = Factory(:user, :email => email)
  sql  = "update users set salt = NULL, encrypted_password = NULL, remember_token = NULL where id = #{user.id}"
  ActiveRecord::Base.connection.update(sql)
end

# Session

Then /^I should be signed in$/ do
  Then %{I should see "sign out"}
end

Then /^I should be signed out$/ do
  Then %{I should see "sign in"}
end

Given /^(?:I am|I have|I) signed in (?:with|as) "(.*)"$/ do |email|
  Given %{I am signed up as "#{email}"}
  And %{I sign in as "#{email}"}
end

Given /^I sign in$/ do
  email = Factory.next(:email)
  Given %{I have signed in with "#{email}"}
end

# Emails

Then /^a password reset message should be sent to "(.*)"$/ do |email|
  user = User.find_by_email(email)
  assert !user.confirmation_token.blank?
  assert !ActionMailer::Base.deliveries.empty?
  result = ActionMailer::Base.deliveries.any? do |email|
    email.to      == [user.email] &&
    email.subject =~ /password/i &&
    email.body    =~ /#{user.confirmation_token}/
  end
  assert result
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

# Actions
When /^I sign in (?:with|as) "(.*)"$/ do |email|
  When %{I go to the sign in page}
  And %{I fill in "Email" with "#{email}"}
  And %{I fill in "Password" with "password"}
  And %{I press "Sign in"}
end

When "I sign out" do
  steps %{
    When I go to the homepage
    And I follow "sign out"
  }
end

When /^I request password reset link to be sent to "(.*)"$/ do |email|
  When %{I go to the password reset request page}
  And %{I fill in "Email address" with "#{email}"}
  And %{I press "Reset password"}
end

When /^I update my password with "(.*)"$/ do |password|
  And %{I fill in "Password" with "#{password}"}
  And %{I press "Save this password"}
end
