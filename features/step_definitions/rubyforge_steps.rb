Given /^a RubyForge user signs in with "([^\"]*)\/(.*)"$/ do |email,password|
  Then %{I sign in as "#{email}/#{password}"}
end

Given /^I have a RubyForge account with "([^\"]*)\/(.*)"$/ do |email,password|
  @rf = Rubyforger.create(
          :email => email,
          :encrypted_password => Digest::MD5.hexdigest(password))
end

Given /^I am a RubyForge user with an email of "([^\"]*)"$/ do |email|
  @rf = Rubyforger.create(
          :email => "email@person.com",
          :encrypted_password => Digest::MD5.hexdigest("password"))
end

Given /^I am a legacy user with (.*)$/ do |creds|
  Given "I signed up with #{creds}"
end

Given /^my RubyForge password is "([^\"]*)"$/ do |password|
  @rf.encrypted_password == Digest::MD5.hexdigest(password)
end

Then /^my GemCutter password should be "([^\"]+)"/ do |password|
  assert(User.authenticate(@rf.email, password))
end

Then /^my GemCutter password should not be "([^\"]+)"/ do |password|
  assert(!User.authenticate(@rf.email, password))
end

Then /^a confirmed user with an email of "([^\"]*)" exists$/ do |email|
  assert(User.find_by_email(email))  
end

Then /^no RubyForge user exists with an email of "([^\"]*)"$/ do |email|
  assert(!Rubyforger.find_by_email(email))
end



