Then /^the webhook should receive a hit for "([^\"]*)" version "([^\"]*)"$/ do 
  |gem_name, version|
  WebMock.assert_requested(:post, @web_hook_url, :times => 1)
  # A bit of hackiness because WebMock won't let us make assertions about the body besides equality
  actual_requests =  WebMock::RequestRegistry.instance.requested_signatures.hash.keys
  assert actual_requests.any? { |request|
    body = JSON.parse(request.body)
    body['name']==gem_name && body['version']==version
  }
end
