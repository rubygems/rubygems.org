class WebHook < ActiveRecord::Base
  belongs_to :user
  belongs_to :rubygem

  named_scope :global, :conditions => {:rubygem_id => nil}
  named_scope :specific, :conditions => "rubygem_id is not null"

  GLOBAL_PATTERN = '*'

  validates_url_format_of :url

  def validate_on_create
    if user && rubygem
      if WebHook.exists?(:user_id    => user.id,
                         :rubygem_id => rubygem.id,
                         :url        => url)
        errors.add_to_base("A hook for #{url} has already been registered for #{rubygem.name}")
      end
    elsif user
      if WebHook.exists?(:user_id    => user.id,
                         :rubygem_id => nil,
                         :url        => url)
        errors.add_to_base("A global hook for #{url} has already been registered")
      end
    else
      errors.add_to_base("A user is required for this hook")
    end
  end

  def fire(host_with_port, deploy_gem, version, delayed = true)
    job = WebHookJob.new(self.url, host_with_port, deploy_gem, version)

    if delayed
      Delayed::Job.enqueue job, PRIORITIES[:web_hook]
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
    {'url' => url, 'failure_count' => failure_count}
  end

  def to_yaml(options = {})
    payload.to_yaml(*options)
  end

  def to_json(options = {})
    payload.to_json(options)
  end
end
