Then /^an empty "(.*)" view for "(.*)" should be generated$/ do |action, controller|
  assert_generated_views_for(controller, action)
end

