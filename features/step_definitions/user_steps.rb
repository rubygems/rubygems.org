Then /^I should see my (.*)$/ do |humanized_attribute|
  attribute = humanized_attribute.downcase.gsub(/\s/, '_')
  assert_match @me.send(attribute), response.body
end

