class GeoipInfo < ApplicationRecord
  has_many :ip_addresses, dependent: :nullify
  has_many :user_events, class_name: "Events::UserEvent", dependent: :nullify
  has_many :rubygem_events, class_name: "Events::RubygemEvent", dependent: :nullify

  validates :continent_code, :country_code, length: { maximum: 2 }
  validates :country_code3, length: { maximum: 3 }

  def to_s
    parts = [city&.titleize, region&.upcase, country_code&.upcase].compact
    if !parts.empty?
      parts.join(", ")
    elsif country_name
      country_name
    else
      "Unknown"
    end
  end
end
