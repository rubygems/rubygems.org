Then /^a cookie named "(\w+)" should( not)? be set$/ do |cookie_name, should_not|
  cookie = Capybara.current_session.driver.request.cookies[cookie_name]

  if should_not
    assert_nil cookie
  else
    assert_not_nil cookie
  end
end
