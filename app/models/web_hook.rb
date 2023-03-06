class WebHook < ApplicationRecord
  GLOBAL_PATTERN = "*".freeze
  TOO_MANY_FAILURES_DISABLED_REASON = "too many failures since the last success".freeze
  FAILURE_DISABLE_THRESHOLD = 25
  FAILURE_DISABLE_DURATION = 1.month

  belongs_to :user
  belongs_to :rubygem, optional: true

  has_many :audits, as: :auditable, dependent: nil

  validates_formatting_of :url, using: :url, message: "does not appear to be a valid URL"
  validates :url, length: { maximum: Gemcutter::MAX_FIELD_LENGTH }, presence: true
  validate :unique_hook, on: :create

  default_scope { enabled }

  scope :global, -> { where(rubygem_id: nil) }

  scope :specific, -> { where.not(rubygem_id: nil) }

  scope :enabled, -> { where(disabled_at: nil) }

  def fire(protocol, host_with_port, version, delayed: true)
    job = NotifyWebHookJob.new(webhook: self, protocol:, host_with_port:, version:)

    if delayed
      job.enqueue
    else
      job.perform_now
    end
  end

  def api_key
    user.api_key || user.api_keys.first&.hashed_key
  end

  def global?
    rubygem_id.blank?
  end

  def enabled?
    disabled_at.blank?
  end

  def success_message
    "Successfully created webhook for #{what} to #{url}"
  end

  def removed_message
    "Successfully removed webhook for #{what} to #{url}"
  end

  def deployed_message(rubygem)
    "Successfully deployed webhook for #{what(rubygem)} to #{url}"
  end

  def failed_message(rubygem)
    "There was a problem deploying webhook for #{what(rubygem)} to #{url}"
  end

  def what(rubygem = self.rubygem)
    if rubygem
      rubygem.name
    else
      "all gems"
    end
  end

  def payload
    {
      "failure_count" => failure_count,
      "url"           => url
    }
  end

  def as_json(*)
    payload
  end

  def to_xml(options = {})
    payload.to_xml(options.merge(root: "web_hook"))
  end

  def to_yaml(*args)
    payload.to_yaml(*args)
  end

  def encode_with(coder)
    coder.tag = nil
    coder.implicit = true
    coder.map = payload
  end

  def success!(completed_at:)
    transaction do
      if happened_after?(completed_at, last_failure)
        increment :successes_since_last_failure
        self.failures_since_last_success = 0
      end
      self.last_success = completed_at if happened_after?(completed_at, last_success)
      save!
    end
  end

  def failure!(completed_at:)
    transaction do
      increment :failure_count
      if happened_after?(completed_at, last_success)
        increment :failures_since_last_success
        self.successes_since_last_failure = 0
      end
      self.last_failure = completed_at if happened_after?(completed_at, last_failure)
      save!
    end

    return unless failures_since_last_success >= FAILURE_DISABLE_THRESHOLD && ((last_success.presence || created_at) < FAILURE_DISABLE_DURATION.ago)
    disable!(TOO_MANY_FAILURES_DISABLED_REASON)
  end

  def disable!(disabled_reason)
    transaction do
      update!(disabled_reason:)
      touch(:disabled_at)

      WebHooksMailer.webhook_disabled(self).deliver_later
    end
  end

  private

  def unique_hook
    if user && rubygem
      if WebHook.exists?(user_id: user.id,
                         rubygem_id: rubygem.id,
                         url: url)
        errors.add(:base, "A hook for #{url} has already been registered for #{rubygem.name}")
      end
    elsif user
      if WebHook.exists?(user_id: user.id,
                         rubygem_id: nil,
                         url: url)
        errors.add(:base, "A global hook for #{url} has already been registered")
      end
    else
      errors.add(:base, "A user is required for this hook")
    end
  end

  def happened_after?(event, reference)
    return true if reference.nil?

    event.after?(reference)
  end
end
