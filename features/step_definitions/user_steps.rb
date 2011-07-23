Then /^I should see my new "(.*)"$/ do |humanized_attribute|
  attribute = humanized_attribute.downcase.gsub(/\s/, '_')
  previous_value = @me.send(attribute)
  new_value = @me.reload.send(attribute)
  assert_not_equal previous_value, new_value,
    "New value for #{humanized_attribute} expected but it hasn't changed!"
  assert_match new_value, page.body
end

Then /^I should see my "(.*)"$/ do |humanized_attribute|
  attribute = humanized_attribute.downcase.gsub(/\s/, '_')
  assert_match @me.send(attribute), page.body
end
