When /^I have added a webhook for "([^\"]*)" to gem "([^\"]*)" with my API key$/ do |web_hook_url, gem_name|
  api_key_header
  WebMock.stub_request(:post, web_hook_url)
  page.driver.post api_v1_web_hooks_path, :gem_name => gem_name, :url => web_hook_url
end

When /^I have added a global webhook for "([^\"]*)" with my API key$/ do |web_hook_url|
  api_key_header
  WebMock.stub_request(:post, web_hook_url)
  page.driver.post api_v1_web_hooks_path, :gem_name => WebHook::GLOBAL_PATTERN, :url => web_hook_url
end

When /I list the webhooks as (json|yaml) with my API key/ do |format|
  api_key_header
  visit api_v1_web_hooks_path(:format => format)
end

Then /^the webhook "([^\"]*)" should receive a POST with gem "([^\"]*)" at version "([^\"]*)"$/ do |web_hook_url, gem_name, version_number|
  WebMock.assert_requested(:post, web_hook_url, :times => 1)

  request = WebMock::RequestRegistry.instance.requested_signatures.hash.keys.first
  json = ActiveSupport::JSON.decode(request.body)

  assert_equal gem_name, json["name"]
  assert_equal version_number, json["version"]
end

Then /I should see "(.*)" under "(.*)" in (json|yaml)/ do |web_hook_url, gem_name, format|
  if format == "json"
    data = ActiveSupport::JSON.decode(page.source)
  else
    data = YAML.load(page.source)
  end

  assert data[gem_name]
  assert data[gem_name].find { |hook| hook['url'] == web_hook_url }
end

When /^I have removed a webhook for "([^\"]*)" from gem "([^\"]*)" with my API key$/ do |web_hook_url, gem_name|
  api_key_header
  page.driver.delete remove_api_v1_web_hooks_path, :gem_name => gem_name, :url => web_hook_url
end

When /^I have removed the global webhook for "([^\"]*)"$/ do |web_hook_url|
  api_key_header
  page.driver.delete remove_api_v1_web_hooks_path, :gem_name => WebHook::GLOBAL_PATTERN, :url => web_hook_url
end

When /^I have fired a webhook to "([^\"]*)" for the "([^\"]*)" gem with my API key$/ do |web_hook_url, gem_name|
  api_key_header
  page.driver.post fire_api_v1_web_hooks_path, :gem_name => gem_name, :url => web_hook_url
end

When /^I have fired a webhook to "([^\"]*)" for all gems with my API key$/ do |web_hook_url|
  api_key_header
  page.driver.post fire_api_v1_web_hooks_path, :gem_name => WebHook::GLOBAL_PATTERN, :url => web_hook_url
end

Then /^the webhook "([^\"]*)" should not receive a POST$/ do |web_hook_url|
  WebMock.assert_not_requested(:post, web_hook_url)
end
