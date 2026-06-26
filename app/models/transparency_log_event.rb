# frozen_string_literal: true

# Captures the signed payload and Rekor submission state for a RubyGems transparency log event.
class TransparencyLogEvent < ApplicationRecord
  STATUSES = {
    pending: "pending",
    submitted: "submitted",
    failed: "failed"
  }.freeze

  SUBMITTED_REKOR_ATTRIBUTES = %i[
    rekor_response_body
    rekor_log_origin
    rekor_entry_kind
    rekor_entry_version
    rekor_log_index
    rekor_submitted_at
  ].freeze

  IMMUTABLE_EVENT_ATTRIBUTES = %w[
    event_uuid
    event_type
    resource_type
    resource_name
    resource_id
    subject_type
    subject_name
    subject_id
    subject_handle
    actor_type
    actor_id
    actor_handle
    authentication_method
    canonical_payload
    canonicalization_algorithm
    canonicalization_version
    payload_digest_algorithm
    payload_digest
    signing_mode
    signing_key_id
    signing_algorithm
    signature
    public_key_id
    public_key_der
    rekor_request_body
    spec_version
    corrects_event_uuid
  ].freeze

  enum :status, STATUSES, default: :pending, validate: true

  scope :for_resource, ->(type, name) { where(resource_type: type, resource_name: name) }
  scope :of_event_type, ->(event_type) { where(event_type:) }
  scope :by_actor, lambda { |type:, id: nil, handle: nil|
    relation = where(actor_type: type)
    relation = relation.where(actor_id: id) if id.present?
    relation = relation.where(actor_handle: handle) if handle.present?
    relation
  }
  scope :created_between, ->(start_time, end_time) { where(created_at: start_time..end_time) }
  scope :pending_submission, -> { pending.order(:created_at, :id) }
  scope :submitted_to_rekor, -> { submitted.where.not(rekor_submitted_at: nil) }
  scope :stale_pending_submission, ->(older_than:) { pending.where(created_at: ...older_than) }

  before_validation :assign_event_uuid, on: :create

  validates :event_uuid,
    :event_type,
    :resource_type,
    :resource_name,
    :subject_type,
    :subject_name,
    :actor_type,
    :actor_id,
    :authentication_method,
    :canonical_payload,
    :canonicalization_algorithm,
    :canonicalization_version,
    :payload_digest_algorithm,
    :payload_digest,
    :signing_mode,
    :signing_key_id,
    :signing_algorithm,
    :signature,
    :public_key_id,
    :public_key_der,
    :rekor_request_body,
    :spec_version,
    presence: true
  validates :event_uuid, uniqueness: true
  validates :payload_digest, uniqueness: { scope: :payload_digest_algorithm }
  validates :attempt_count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  validates :event_type, length: { maximum: 100 }
  validates :resource_type, :subject_type, :actor_type, length: { maximum: 50 }
  validates :resource_name, :subject_name, length: { maximum: 255 }
  validates :resource_id, :subject_id, :subject_handle, :actor_id, :actor_handle, :signing_key_id, :public_key_id, length: { maximum: 128 }
  validates :authentication_method, length: { maximum: 100 }
  validates :canonicalization_algorithm, :signing_algorithm, length: { maximum: 64 }
  validates :canonicalization_version, :rekor_entry_version, :spec_version, length: { maximum: 32 }
  validates :payload_digest_algorithm, :status, length: { maximum: 32 }
  validates :signing_mode, :rekor_entry_kind, length: { maximum: 50 }
  validates :rekor_log_origin, length: { maximum: 255 }

  validate :canonical_payload_is_object
  validate do
    TransparencyLogEvent::CanonicalPayloadContract.new(event: self).validate if canonical_payload.is_a?(Hash)
  end
  validate :rekor_request_body_is_object
  validate :submitted_events_include_rekor_details
  validate :failed_events_include_error
  validate :rekor_log_index_is_non_negative
  validate on: :update do
    TransparencyLogEvent::ImmutableEventContent.new(event: self).validate
  end

  def self.find_by_digest(algorithm, digest)
    find_by(payload_digest_algorithm: algorithm, payload_digest: digest)
  end

  def self.submission_health
    TransparencyLogEvent::SubmissionHealth.new(relation: all)
  end

  def encoded_payload_digest
    Base64.strict_encode64(payload_digest)
  end

  def encoded_signature
    Base64.strict_encode64(signature)
  end

  def encoded_public_key_der
    Base64.strict_encode64(public_key_der)
  end

  def subject
    "#{subject_type}:#{subject_name}"
  end

  def resource
    "#{resource_type}:#{resource_name}"
  end

  def actor
    actor_handle.presence || "#{actor_type}:#{actor_id}"
  end

  def record_submission(response_body:, rekor_entry:, submitted_at: Time.current)
    unless pending?
      errors.add(:status, "cannot transition from #{status} to submitted")
      return false
    end

    update(
      status: :submitted,
      rekor_response_body: response_body,
      rekor_submitted_at: submitted_at,
      last_error: nil,
      **rekor_entry.event_attributes
    )
  end

  def record_failure(error)
    with_lock do
      unless pending?
        errors.add(:status, "cannot transition from #{status} to failed")
        next false
      end

      update(
        status: :failed,
        attempt_count: attempt_count + 1,
        last_error: error.to_s
      )
    end
  end

  def retry_submission
    unless failed?
      errors.add(:status, "cannot transition from #{status} to pending")
      return false
    end

    update(
      status: :pending,
      last_error: nil
    )
  end

  private

  def assign_event_uuid
    self.event_uuid ||= SecureRandom.uuid
  end

  def canonical_payload_is_object
    errors.add(:canonical_payload, "must be a JSON object") unless canonical_payload.is_a?(Hash)
  end

  def rekor_request_body_is_object
    errors.add(:rekor_request_body, "must be a JSON object") unless rekor_request_body.is_a?(Hash)
  end

  def submitted_events_include_rekor_details
    return unless submitted?

    SUBMITTED_REKOR_ATTRIBUTES.each do |attribute|
      errors.add(attribute, "can't be blank") if public_send(attribute).blank?
    end
  end

  def failed_events_include_error
    errors.add(:last_error, "can't be blank") if failed? && last_error.blank?
  end

  def rekor_log_index_is_non_negative
    return if rekor_log_index.blank? || rekor_log_index >= 0

    errors.add(:rekor_log_index, "must be greater than or equal to 0")
  end
end
