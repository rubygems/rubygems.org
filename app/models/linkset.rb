class Linkset < ApplicationRecord
  belongs_to :rubygem

  LINKS = %w[home code docs wiki mail bugs].freeze

  LINKS.each do |url|
    validates_formatting_of url.to_sym,
      using: :url,
      allow_nil: true,
      allow_blank: true,
      message: "does not appear to be a valid URL"
    validates url,
      :linkback => true,
      on: :verify_linkbacks,
      allow_nil: true,
      allow_blank: true
  end

  after_validation :record_linkback_verification, on: :verify_linkbacks

  def empty?
    LINKS.map { |link| attributes[link] }.all?(&:blank?)
  end

  def update_attributes_from_gem_specification!(spec)
    update!(home: spec.homepage)
  end

  def verify_linkbacks
    return if rubygem[:indexed].blank?
    validate(:verify_linkbacks)
    save
  end

  private

  def record_linkback_verification
    LINKS.map { |key| self["#{key}_verified"] = self[key].nil? ? nil : self.errors[key].empty? }
    return true
  end
end
