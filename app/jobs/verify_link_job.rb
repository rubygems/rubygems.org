class VerifyLinkJob < ApplicationJob
  queue_as :default

  retry_on ActiveRecord::RecordNotFound, ActiveRecord::RecordInvalid, wait: :polynomially_longer, attempts: 3

  ERRORS = (HTTP_ERRORS + [Faraday::Error, SocketError, SystemCallError, OpenSSL::SSL::SSLError]).freeze

  class NotHTTPSError < StandardError; end
  class LinkNotPresentError < StandardError; end
  class HTTPResponseError < StandardError; end

  rescue_from NotHTTPSError do |_error|
    record_failure
  end

  rescue_from LinkNotPresentError, HTTPResponseError, *ERRORS do |error|
    logger.info "Linkback verification failed with error: #{error.message}", error: error, uri: link_verification.uri,
      linkable: link_verification.linkable.to_gid

    link_verification.transaction do
      record_failure
      retry_job(wait: 5.seconds * (3.5**link_verification.failures_since_last_verification.pred), error:) if should_retry?
    end
  end

  TIMEOUT_SEC = 5

  def perform(link_verification:)
    verify_link!(link_verification.uri, link_verification.linkable)
    record_success
  end

  def link_verification
    arguments.first.fetch(:link_verification)
  end

  def verify_link!(uri, linkable)
    raise NotHTTPSError unless uri.start_with?("https://")

    expected_href = linkable.linkable_verification_uri.to_s.downcase

    response = get(uri)
    raise HTTPResponseError, "Expected 200, got #{response.status}" unless response.status == 200
    # TODO: body_with_limit, https://github.com/mastodon/mastodon/blob/33c8708a1ac7df363bf2bd74ab8fa2ed7168379c/app/lib/request.rb#L246
    doc = Nokogiri::HTML5(response.body)

    xpaths = [
      # rel=me, what mastodon uses for profile link verification
      '//a[contains(concat(" ", normalize-space(@rel), " "), " me ")]',
      '//link[contains(concat(" ", normalize-space(@rel), " "), " me ")]',

      # rel=rubygem
      '//a[contains(concat(" ", normalize-space(@rel), " "), " rubygem ")]',
      '//link[contains(concat(" ", normalize-space(@rel), " "), " rubygem ")]'
    ]

    if URI(uri).host == "github.com"
      # github doesn't set a rel attribute on the URL added to a repo, so we have to use role=link instead
      xpaths << '//a[contains(concat(" ", normalize-space(@role), " "), " link ")]'
      xpaths << '//link[contains(concat(" ", normalize-space(@role), " "), " link ")]'
    end

    links = doc.xpath(xpaths.join("|"))

    return if links.any? { |link| link["href"]&.downcase == expected_href }
    raise LinkNotPresentError, "Expected #{expected_href} to be present in #{uri}"
  end

  def get(url)
    Faraday.new(nil, request: { timeout: TIMEOUT_SEC }) do |f|
      f.response :logger, logger, headers: false, errors: true
      f.response :raise_error
    end.get(
      url,
      {},
      {
        "User-Agent" => "RubyGems.org Linkback Verification/#{AppRevision.version}",
        "Accept" => "text/html"
      }
    )
  end

  def should_retry?
    link_verification.failures_since_last_verification < LinkVerification::MAX_FAILURES
  end

  def record_success
    link_verification.update!(
      last_verified_at: Time.current,
      failures_since_last_verification: 0
    )
  end

  def record_failure
    link_verification.touch(:last_failure_at)
    link_verification.increment!(:failures_since_last_verification)
  end
end
