require 'timeout'

Notifier = Struct.new(:url, :protocol, :host_with_port, :rubygem, :version, :api_key) do
  extend StatsD::Instrument

  def payload
    rubygem.payload(version, protocol, host_with_port).to_json
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
  rescue *(HTTP_ERRORS + [RestClient::Exception, SocketError, SystemCallError])
    WebHook.find_by_url(url).try(:increment!, :failure_count)
    false
  end
  statsd_count_success :perform, 'Webhook.perform.success'

  private

  def timeout(sec, &block)
    Timeout.timeout(sec, &block)
  end
end
