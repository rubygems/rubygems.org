class IpAddress < ApplicationRecord
  validates :ip_address, presence: true, uniqueness: true
  validates :hashed_ip_address, presence: true, uniqueness: true

  validates :geoip_info, presence: true, allow_nil: true
  attribute :geoip_info, Types::JsonDeserializable.new(GeoipInfo)

  before_validation :hash_ip_address!

  has_many :user_events, class_name: "Events::UserEvent", dependent: :nullify
  has_many :rubygem_events, class_name: "Events::RubygemEvent", dependent: :nullify

  def hash_ip_address!
    self.hashed_ip_address ||= Digest::SHA256.hexdigest(ip_address.to_s)
  end

  delegate :to_s, to: :ip_address
end
