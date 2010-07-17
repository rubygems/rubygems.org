class WebHookJob < Struct.new(:url, :host_with_port, :rubygem, :version)

  def payload
    rubygem.payload(version, host_with_port).to_json
  end

  def perform
    SystemTimer.timeout_after(5) do
      RestClient.post url,
                      payload,
                      :timeout       => 5,
                      :open_timeout  => 5,
                      'Content-Type' => 'application/json'
    end
    true
  rescue *(HTTP_ERRORS + [RestClient::Exception, SocketError]) => e
    WebHook.find_by_url(url).try(:increment!, :failure_count)
    false
  end

end
