# frozen_string_literal: true

class VerifyLinkbacksJob < ApplicationJob
  queue_as :default

  retry_on ActiveRecord::RecordNotFound, ActiveRecord::RecordInvalid, wait: :exponentially_longer, attempts: 3

  def perform(rubygem_id)
    rubygem = Rubygem.with_versions.find(rubygem_id)
    linkset = rubygem.linkset
    gem_name = rubygem.name

    Linkset::LINKS.each do |link|
      url = linkset.read_attribute(link)
      next if url.blank?
      linkset["#{link}_verified_at"] = valid_link?(url, gem_name) ? Time.current : nil
    end
    linkset.save!
  end

  def valid_link?(url, gem_name)
    Timeout.timeout(5) do
      response = RestClient.get(
        url,
        timeout: 5,
        open_timeout: 5,
        accept: :html
      )
      doc = Nokogiri::HTML(response.body)
      selector = ["github.com"].include?(URI(url).host) ? "[role='link']" : "[rel='rubygem']"
      doc.css(selector).css("[href*='rubygems.org/gem/#{gem_name}']").present?
    end
  rescue *(HTTP_ERRORS + [RestClient::Exception, SocketError, SystemCallError])
    false
  end
end
