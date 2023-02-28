class NotifyWebHookJob < ApplicationJob
  extend StatsD::Instrument
  include TraceTagger

  queue_as :default
  self.queue_adapter = :good_job

  before_perform { @kwargs = arguments.last.then { _1 if Hash.ruby2_keywords_hash?(_1) } }
  before_perform { @webhook = @kwargs.fetch(:webhook) }
  before_perform { @protocol = @kwargs.fetch(:protocol) }
  before_perform { @host_with_port = @kwargs.fetch(:host_with_port) }
  before_perform { @version = @kwargs.fetch(:version) }
  before_perform { @rubygem = @version.rubygem }

  attr_reader :webhook, :protocol, :host_with_port, :version, :rubygem

  def perform(*)
    url = webhook.url
    set_tag "gemcutter.notifier.url", url
    set_tag "gemcutter.notifier.webhook_id", webhook.id

    timeout(5) do
      RestClient.post url,
        payload,
        :timeout        => 5,
        :open_timeout   => 5,
        "Content-Type"  => "application/json",
        "Authorization" => authorization
    end
    true
  rescue *(HTTP_ERRORS + [RestClient::Exception, SocketError, SystemCallError]) => _e
    webhook.increment! :failure_count
    false
  end
  statsd_count_success :perform, "Webhook.perform"

  def payload
    rubygem.payload(version, protocol, host_with_port).to_json
  end

  def authorization
    Digest::SHA2.hexdigest([rubygem.name, version.number, webhook.api_key].compact.join)
  end

  private

  def timeout(sec, &)
    Timeout.timeout(sec, &)
  end
end
