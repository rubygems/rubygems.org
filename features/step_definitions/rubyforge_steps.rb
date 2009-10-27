Given /^a RubyForge user signs in with "([^\"]*)\/(.*)"$/ do |email,password|
  Given %{I am a RubyForge user with an email of "#{email}"}
  And %{my RubyForge password is "#{password}"}
  And %{I sign in as "#{email}/#{password}"}
end

Given /^I am a RubyForge user with an email of "([^\"]*)"$/ do |email|
  @rf = Rubyforger.create(
          :email => "email@person.com",
          :encrypted_password => Digest::MD5.hexdigest("password"))
end

Then /^my RubyForge password is "([^\"]*)"$/ do |password|
  @rf.encrypted_password == Digest::MD5.hexdigest(password)
end

Then /^a confirmed user with an email of "([^\"]*)" exists$/ do |email|
  assert(User.find_by_email(email))  
end

Then /^no RubyForge user exists with an email of "([^\"]*)"$/ do |email|
  assert(!Rubyforger.find_by_email(email))
end

Given /^a RubyForge user exists with an email of "([^\"]*)"$/ do |email|
  
end


