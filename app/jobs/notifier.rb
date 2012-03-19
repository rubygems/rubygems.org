class Notifier < Struct.new(:event, :url, :host_with_port, :rubygem, :version, :api_key)

  def payload
    rubygem_payload = rubygem.payload(version, host_with_port)
    base = {"event" => event, "rubygem" => rubygem_payload}
    payload = event == "push" ? rubygem_payload.merge(base) : base
    payload.to_json
  end

  def authorization
    Digest::SHA2.hexdigest(rubygem.name + version.number + api_key)
  end

  def perform
    timeout(5) do
      RestClient.post url,
                      payload,
                      :timeout        => 5,
                      :open_timeout   => 5,
                      'Content-Type'  => 'application/json',
                      'Authorization' => authorization
    end
    true
  rescue *(HTTP_ERRORS + [RestClient::Exception, SocketError, SystemCallError]) => e
    WebHook.find_by_url(url).try(:increment!, :failure_count)
    false
  end

  private

  if RUBY_VERSION < '1.9.2'
    def timeout(sec, &block)
      SystemTimer.timeout_after(sec, &block)
    end
  else
    require 'timeout'

    def timeout(sec, &block)
      Timeout.timeout(sec, &block)
    end
  end
end
