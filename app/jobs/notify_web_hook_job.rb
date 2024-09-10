class NotifyWebHookJob < ApplicationJob
  extend StatsD::Instrument
  include TraceTagger

  queue_as :default
  queue_with_priority PRIORITIES.fetch(:web_hook)

  TIMEOUT_SEC = 5

  before_perform { @kwargs = arguments.last.then { _1 if Hash.ruby2_keywords_hash?(_1) } }
  before_perform { @webhook = @kwargs.fetch(:webhook) }
  before_perform { @protocol = @kwargs.fetch(:protocol) }
  before_perform { @host_with_port = @kwargs.fetch(:host_with_port) }
  before_perform { @version = @kwargs.fetch(:version) }
  before_perform { @rubygem = @version.rubygem }
  before_perform { @poll_delivery = @kwargs.fetch(:poll_delivery, false) }
  before_perform do
    @http = Faraday.new("https://api.hookrelay.dev", request: { timeout: TIMEOUT_SEC }) do |f|
      f.request :json
      f.response :logger, logger, headers: false, errors: true
      f.response :json
      f.response :raise_error
    end
  end

  attr_reader :webhook, :protocol, :host_with_port, :version, :rubygem

  ERRORS = (HTTP_ERRORS + [Faraday::Error, SocketError, SystemCallError, OpenSSL::SSL::SSLError]).freeze
  retry_on(*ERRORS)

  # has to come after the retry on
  discard_on(Faraday::UnprocessableEntityError) do |j, e|
    logger.info({ webhook_id: j.webhook.id, url: j.webhook.url, response: JSON.parse(e.response_body) })
    j.webhook.increment! :failure_count
  end

  def perform(*)
    url = webhook.url
    set_tag "gemcutter.notifier.url", url
    set_tag "gemcutter.notifier.webhook_id", webhook.id

    post_hook_relay
  end
  statsd_count_success :perform, "Webhook.perform"

  def payload
    rubygem.payload(version, protocol, host_with_port).to_json
  end

  def authorization
    Digest::SHA2.hexdigest([rubygem.name, version.number, webhook.api_key].compact.join)
  end

  def hook_relay_url
    "https://api.hookrelay.dev/hooks/#{account_id}/#{hook_id}/webhook_id-#{webhook.id || 'fire'}"
  end

  def post_hook_relay
    response = post(hook_relay_url)
    delivery_id = response.body.fetch("id")
    Rails.logger.info do
      { webhook_id: webhook.id, url: webhook.url, delivery_id:, full_name: version.full_name, message: "Sent webhook to HookRelay" }
    end
    return poll_delivery(delivery_id) if @poll_delivery
    true
  end

  def post(url)
    @http.post(
      url, payload,
      {
        "Authorization"   => authorization,
        "HR_TARGET_URL"   => webhook.url,
        "HR_MAX_ATTEMPTS" => @poll_delivery ? "1" : "3"
      }
    )
  end

  def poll_delivery(delivery_id)
    deadline = (Rails.env.test? ? 0.01 : 10).seconds.from_now
    response = nil
    until Time.zone.now > deadline
      sleep 0.5
      response = @http.get("https://app.hookrelay.dev/api/v1/accounts/#{account_id}/hooks/#{hook_id}/deliveries/#{delivery_id}", nil, {
                             "Authorization" => "Bearer #{ENV['HOOK_RELAY_API_KEY']}"
                           })
      status = response.body.fetch("status")

      break if status == "success"
    end

    response.body || raise("Failed to get delivery status after 10 seconds")
  end

  private

  def account_id
    ENV["HOOK_RELAY_ACCOUNT_ID"]
  end

  def hook_id
    ENV["HOOK_RELAY_HOOK_ID"]
  end
end
