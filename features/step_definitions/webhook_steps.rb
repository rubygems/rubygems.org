Then /^the webhook "([^\"]*)" should receive a POST$/ do |web_hook_url|
  WebMock.assert_requested(:post, web_hook_url, :times => 1)
end
