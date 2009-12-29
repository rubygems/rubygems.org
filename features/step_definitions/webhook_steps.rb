Then /^the webhook "([^\"]*)" should receive a POST with gem "([^\"]*)" at version "([^\"]*)"$/ do |web_hook_url, gem_name, version_number|
  WebMock.assert_requested(:post, web_hook_url, :times => 1)

  request = WebMock::RequestRegistry.instance.requested_signatures.hash.keys.first
  json = ActiveSupport::JSON.decode(request.body)

  assert_equal gem_name, json["name"]
  assert_equal version_number, json["version"]
end
