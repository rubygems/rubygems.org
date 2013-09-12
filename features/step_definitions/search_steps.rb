When /^I search for "([^"]*)"$/ do |query|
  steps %{
    When I go to the homepage
    And I fill in "query" with "#{query}"
    And I press "Search"
  }
end

Then /^I should see these search results:$/ do |expected_table|
  # TODO: Make less brittle with an explicit CSS class in the view
  results  = page.all(".gems:last-child li a strong").collect(&:text)

  assert_not_empty results
  expected_table.diff! Cucumber::Ast::Table.new( results.map { |r| Array(r) } )
end
