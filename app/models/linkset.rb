class Linkset < ApplicationRecord
  belongs_to :rubygem

  before_save :create_homepage_link_verification, if: :home_changed?

  LINKS = %w[home code docs wiki mail bugs].freeze

  LINKS.each do |url|
    validates_formatting_of url.to_sym,
      using: :url,
      allow_nil: true,
      allow_blank: true,
      message: "does not appear to be a valid URL"
  end

  def empty?
    LINKS.map { |link| attributes[link] }.all?(&:blank?)
  end

  def update_attributes_from_gem_specification!(spec)
    update!(home: spec.homepage)
  end

  def create_homepage_link_verification
    return if home.blank?
    rubygem.link_verifications.find_or_create_by!(uri: home).retry_if_needed
  end
end
