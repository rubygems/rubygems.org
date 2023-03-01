# frozen_string_literal: true

class VerifyLinkbacksJob < ApplicationJob
  queue_as :default

  retry_on ActiveRecord::RecordNotFound, wait: :exponentially_longer, attempts: 3

  def perform(rubygem_id)
    linkset = Rubygem.with_versions.find(rubygem_id).linkset

    Linkset::LINKS.each do |attribute|
      validate_linkset(linkset, attribute, linkset[attribute])
    end
  end

  def validate_linkset(record, attribute, url)
    doc = Nokogiri::HTML(URI.open(url).read)
    selector = url.include?("github.com") ? "[role='link']" : "[rel='rubygem']"
    rel_links = doc.css(selector)

    has_linkback = rel_links.css("[href*='rubygems.org/gem/#{record.rubygem.name}']").present?
    record.errors.add(attribute, "does not contain a #{selector} link back to the gem on rubygems.org") unless has_linkback
  rescue *(HTTP_ERRORS + [RestClient::Exception, SocketError, SystemCallError])
    record.errors.add(attribute, "server error")
  end
end
