class Attestation < ApplicationRecord
  belongs_to :version

  validates :body, :media_type, presence: true
  attribute :body, :jsonb
end
