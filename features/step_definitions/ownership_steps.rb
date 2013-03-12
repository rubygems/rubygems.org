When(/^I add the owner "(.*?)" to the rubygem "(.*?)" through the UI$/) do |owner_email, rubygem_name|
  click_link "Edit Owners"
  fill_in "Email", :with => owner_email
  click_button "Add Owner"
end
