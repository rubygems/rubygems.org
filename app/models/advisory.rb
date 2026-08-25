# frozen_string_literal: true

class Advisory < ApplicationRecord
  belongs_to :rubygem, primary_key: :name, foreign_key: :rubygem_name, optional: true, inverse_of: :advisories

  attribute :payload, :jsonb
  attribute :ranges, :jsonb

  validates :type, :identifier, :rubygem_name, :summary, :url, :modified_at, presence: true
  validates :identifier, uniqueness: { scope: %i[type rubygem_name] }

  scope :current, -> { where(withdrawn_at: nil) }
end
