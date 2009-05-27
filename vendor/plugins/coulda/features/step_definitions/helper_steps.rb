When /^I generate a helper named "(.*)"$/ do |name|
  system "cd #{@rails_root} && " <<
         "script/generate helper #{name} && " <<
         "cd .."
end

Then /^a helper should be generated for "(.*)"$/ do |name|
  assert_generated_helper_for(name)
end

Then /^a helper test should be generated for "(.*)"$/ do |name|
  assert_generated_helper_test_for(name)
end

