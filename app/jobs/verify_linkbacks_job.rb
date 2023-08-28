# frozen_string_literal: true

class VerifyLinkbacksJob < ApplicationJob
  queue_as :default

  retry_on ActiveRecord::RecordNotFound, ActiveRecord::RecordInvalid, wait: :exponentially_longer, attempts: 3

  ERRORS = (HTTP_ERRORS + [Faraday::Error, SocketError, SystemCallError, OpenSSL::SSL::SSLError]).freeze

  TIMEOUT_SEC = 5

  def perform(linkset:)
    rubygem = linkset.rubygem
    return unless rubygem.indexed?

    Linkset::LINKS.map do |link|
      url = linkset[link.to_s]
      next if url.blank?

      linkset["#{link}_verified_at"] = valid_link?(url, rubygem.name) ? Time.current : nil
    end
    linkset.save!
  end

  private

  def valid_link?(url, gem_name)
    response = get(url)
    doc = Nokogiri::HTML(response.body)
    selector = ["github.com"].include?(URI(url).host) ? "[role='link']" : "[rel='rubygem']"
    doc.css(selector).css("[href*='rubygems.org/gem/#{gem_name}']").present?
  rescue *ERRORS => e
    logger.info "Linkback verification failed for #{url} with error: #{e.message}", error: e, url: url, gem_name: gem_name
    false
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
end
