Then /^I should be subscribed to "([^"]*)"$/ do |name|
  assert @me.subscribed_gems.include?(Rubygem.find_by_name(name))
end

Then /^I should be unsubscribed to "([^"]*)"$/ do |name|
  assert !@me.subscribed_gems.include?(Rubygem.find_by_name(name))
end
