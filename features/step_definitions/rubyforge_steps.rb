Given /^I have a RubyForge account with "([^\"]*)\/(.*)"$/ do |email,password|
  @rf = Rubyforger.new(:email => email)
  @rf.encrypted_password = Digest::MD5.hexdigest(password)
  @rf.save
end

Given /^I am a RubyForge user with an email of "([^\"]*)"$/ do |email|
  @rf = Rubyforger.new(:email => "email@person.com")
  @rf.encrypted_password = Digest::MD5.hexdigest("password")
  @rf.save
end

Given /^my RubyForge password is "([^\"]*)"$/ do |password|
  @rf.encrypted_password = Digest::MD5.hexdigest(password)
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
