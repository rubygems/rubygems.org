class Linkset < ApplicationRecord
  belongs_to :rubygem

  LINKS = %w[home code docs wiki mail bugs].freeze

  LINKS.each do |url|
    validates_formatting_of url.to_sym,
      using: :url,
      allow_nil: true,
      allow_blank: true,
      message: "does not appear to be a valid URL"
  end

  after_commit :verify_linkbacks

  def empty?
    LINKS.map { |link| attributes[link] }.all?(&:blank?)
  end

  def update_attributes_from_gem_specification!(spec)
    update!(home: spec.homepage)
  end

  def verified?(link)
    !!self["#{link}_verified_at"]
  end

  def verify_linkbacks
    VerifyLinkbacksJob.perform_later(rubygem.id)
  end
end
