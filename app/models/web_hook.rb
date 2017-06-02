class WebHook < ApplicationRecord
  GLOBAL_PATTERN = '*'.freeze

  belongs_to :user
  belongs_to :rubygem

  validates_formatting_of :url, using: :url, message: "does not appear to be a valid URL"
  validate :unique_hook, on: :create

  def self.global
    where(rubygem_id: nil)
  end

  def self.specific
    where.not(rubygem_id: nil)
  end

  def fire(protocol, host_with_port, deploy_gem, version, delayed = true)
    job = Notifier.new(url, protocol, host_with_port, deploy_gem, version, user.api_key)
    if delayed
      Delayed::Job.enqueue job, priority: PRIORITIES[:web_hook]
    else
      job.perform
    end
  end

  def global?
    rubygem_id.blank?
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
      'failure_count' => failure_count,
      'url'           => url
    }
  end

  def as_json(*)
    payload
  end

  def to_xml(options = {})
    payload.to_xml(options.merge(root: 'web_hook'))
  end

  def to_yaml(*args)
    payload.to_yaml(*args)
  end

  def encode_with(coder)
    coder.tag = nil
    coder.implicit = true
    coder.map = payload
  end

  private

  def unique_hook
    if user && rubygem
      if WebHook.exists?(user_id: user.id,
                         rubygem_id: rubygem.id,
                         url: url)
        errors[:base] << "A hook for #{url} has already been registered for #{rubygem.name}"
      end
    elsif user
      if WebHook.exists?(user_id: user.id,
                         rubygem_id: nil,
                         url: url)
        errors[:base] << "A global hook for #{url} has already been registered"
      end
    else
      errors[:base] << "A user is required for this hook"
    end
  end
end
