When /^I visit the gem page for "([^\"]*)"$/ do |gem_name|
  When %{I go to the homepage}
  When %{I follow "list"}
  When %{I follow "#{gem_name.first}"}
  When %{I follow "#{gem_name}"}
end

And /^I save and open the page$/ do
  save_and_open_page
end
