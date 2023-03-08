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

  attr_reader :webhook, :protocol, :host_with_port, :version, :rubygem

  ERRORS = (HTTP_ERRORS + [RestClient::Exception, SocketError, SystemCallError, OpenSSL::SSL::SSLError]).freeze
  retry_on(*ERRORS)

  # has to come after the retry on
  discard_on(RestClient::UnprocessableEntity) do |j, e|
    raise unless j.use_hook_relay?
    Rails.logger.info({ webhook_id: j.webhook.id, url: j.webhook.url, response: JSON.parse(e.response.body) }.to_json)
    j.webhook.increment! :failure_count
  end

  def perform(*)
    url = webhook.url
    set_tag "gemcutter.notifier.url", url
    set_tag "gemcutter.notifier.webhook_id", webhook.id

    if use_hook_relay?
      post_hook_relay
    else
      post_directly
    end
  end
  statsd_count_success :perform, "Webhook.perform"

  def payload
    rubygem.payload(version, protocol, host_with_port).to_json
  end

  def authorization
    Digest::SHA2.hexdigest([rubygem.name, version.number, webhook.api_key].compact.join)
  end

  def hook_relay_url
    "https://api.hookrelay.dev/hooks/#{ENV['HOOK_RELAY_ACCOUNT_ID']}/#{ENV['HOOK_RELAY_HOOK_ID']}/webhook_id-#{webhook.id}"
  end

  def use_hook_relay?
    # can't use hook relay for `perform_now` (aka an unenqueued job)
    # because then we won't actually hit the webhook URL synchronously
    enqueued_at.present? && ENV["HOOK_RELAY_ACCOUNT_ID"].present? && ENV["HOOK_RELAY_HOOK_ID"].present?
  end

  def post_hook_relay
    response = post(hook_relay_url)
    delivery_id = JSON.parse(response).fetch("id")
    Rails.logger.info({ webhook_id: webhook.id, url: webhook.url, delivery_id:, full_name: version.full_name }.to_json)
    true
  end

  def post_directly
    post(webhook.url)
    true
  rescue *ERRORS
    webhook.increment! :failure_count
    false
  end

  def post(url)
    timeout(TIMEOUT_SEC) do
      RestClient::Request.execute method: :post,
        url: url,
        payload: payload,
        timeout: TIMEOUT_SEC,
        open_timeout: TIMEOUT_SEC,
        headers: {
          "Content-Type"    => "application/json",
          "Authorization"   => authorization,
          "HR_TARGET_URL"   => webhook.url,
          "HR_MAX_ATTEMPTS" => "3"
        }
    end
  end

  private

  def timeout(sec, &)
    Timeout.timeout(sec, &)
  end
end
