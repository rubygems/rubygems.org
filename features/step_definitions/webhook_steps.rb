When /^I have added a webhook for "([^\"]*)" to gem "([^\"]*)" with my api key$/ do |web_hook_url, gem_name|
  api_key_header
  WebMock.stub_request(:post, web_hook_url)
  visit api_v1_web_hooks_path, :post, :gem_name => gem_name, :url => web_hook_url
end

When /^I have added a global webhook for "([^\"]*)" with my api key$/ do |web_hook_url|
  api_key_header
  WebMock.stub_request(:post, web_hook_url)
  visit api_v1_web_hooks_path,
        :post,
        :gem_name => WebHook::GLOBAL_PATTERN,
        :url      => web_hook_url
end

When /^I list the webhooks with my api key$/ do
  api_key_header
  visit api_v1_web_hooks_path, :get, :format => "json"
end

Then /^the webhook "([^\"]*)" should receive a POST with gem "([^\"]*)" at version "([^\"]*)"$/ do |web_hook_url, gem_name, version_number|
  WebMock.assert_requested(:post, web_hook_url, :times => 1)

  request = WebMock::RequestRegistry.instance.requested_signatures.hash.keys.first
  json = ActiveSupport::JSON.decode(request.body)

  assert_equal gem_name, json["name"]
  assert_equal version_number, json["version"]
end

Then /^I should see "([^\"]*)" under "([^\"]*)"$/ do |web_hook_url, gem_name|
  json = ActiveSupport::JSON.decode(response.body)
  assert json[gem_name]
  assert json[gem_name].find { |hook| hook['url'] == web_hook_url }
end

When /^I have removed a webhook for "([^\"]*)" from gem "([^\"]*)" with my api key$/ do |web_hook_url, gem_name|
  api_key_header
  visit remove_api_v1_web_hooks_path,
        :delete,
        :gem_name => gem_name,
        :url      => web_hook_url
end

When /^I have removed the global webhook for "([^\"]*)"$/ do |web_hook_url|
  api_key_header
  visit remove_api_v1_web_hooks_path,
        :delete,
        :gem_name => WebHook::GLOBAL_PATTERN,
        :url      => web_hook_url
end

When /^I have fired hooks for the "([^\"]*)" gem with my api key$/ do |gem_name|
  api_key_header
  visit fire_api_v1_web_hooks_path, :post, :gem_name => gem_name
end

When /^I have fired global hooks with my api key$/ do
  api_key_header
  visit fire_api_v1_web_hooks_path, :post, :gem_name => WebHook::GLOBAL_PATTERN
end

Then /^the webhook "([^\"]*)" should not receive a POST$/ do |web_hook_url|
  WebMock.assert_not_requested(:post, web_hook_url)
end
