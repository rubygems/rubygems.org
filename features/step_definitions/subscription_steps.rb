Given /^"(.*?)" has subscribed to "(.*?)"$/ do |email, name|
  gem = Rubygem.find_by_name(name)
  user = User.find_by_email(email)
  Subscription.create!(:rubygem_id => gem.id, :user_id => user.id)
end

Then /^a subscription should exist for "(.*?)" to "(.*?)"$/ do |email, name|
  sleep 5
  assert subscription_for_user_and_rubygem(email, name)
end

Then /^a subscription should not exist for "(.*?)" to "(.*?)"$/ do |email, name|
  sleep 5
  assert_nil subscription_for_user_and_rubygem(email, name)
end

def subscription_for_user_and_rubygem(email, name)
  gem = Rubygem.find_by_name(name)
  user = User.find_by_email(email)
  Subscription.find_by_rubygem_id_and_user_id(gem.id, user.id)
end
