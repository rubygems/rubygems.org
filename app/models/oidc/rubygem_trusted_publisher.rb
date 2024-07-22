class OIDC::RubygemTrustedPublisher < ApplicationRecord
  belongs_to :rubygem
  belongs_to :trusted_publisher, polymorphic: true, optional: false

  accepts_nested_attributes_for :trusted_publisher

  validates :rubygem, uniqueness: { scope: %i[trusted_publisher_id trusted_publisher_type] }

  def build_trusted_publisher(params)
    self.trusted_publisher = trusted_publisher_type.constantize.build_trusted_publisher(params)
  end

  def payload
    {
      id:,
      trusted_publisher_type:,
      trusted_publisher: trusted_publisher
    }
  end

  delegate :as_json, to: :payload
end
