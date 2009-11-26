Then /^the webhook should receive a hit for "([^\"]*)" version "([^\"]*)"$/ do 
  |gem_name, version|
  pending
  WebMock.assert_requested(:post, @web_hook_url, :times => 1)
  request_signature = WebMock::RequestSignature.new(:post, @web_hook_url)
  response = WebMock.response_for_request(request_signature)
  body = JSON.parse(response.body)
  assert_equal gem_name, body['name']
  assert_equal version, body['version']
end
