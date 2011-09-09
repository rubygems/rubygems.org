Given /^my handle is "([^\"]*)"$/ do |handle|
  @me.update_attribute :handle, handle
end

Given /^my handle is nil$/ do
  @me.update_attribute :handle, nil
end
