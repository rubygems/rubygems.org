# frozen_string_literal: true

module Maintenance::TransparencyLogBaseline
  extend ActiveSupport::Concern

  included do
    attribute :baseline_id, :string
    attribute :observed_at, :datetime

    validates :baseline_id, :observed_at, presence: true
    validate :baseline_id_is_a_uuid
  end

  private

  def baseline_event
    @baseline_event ||= TransparencyLog::BaselineEvent.new(baseline_id:, observed_at:)
  end

  def baseline_id_is_a_uuid
    return if baseline_id.blank?

    parsed = baseline_id.match?(/\A[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/i)
    errors.add(:baseline_id, "must be a UUID") unless parsed
  end

  def rubygem_resource(rubygem)
    { type: "rubygem", name: rubygem.name, id: rubygem.id.to_s }
  end
end
