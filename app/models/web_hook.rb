class WebHook < ActiveRecord::Base
  belongs_to :user
  belongs_to :rubygem

  named_scope :global, :conditions => {:rubygem_id => nil}
  named_scope :specific, :conditions => "rubygem_id is not null"

  GLOBAL_PATTERN = '*'

  attr_accessor :host_with_port, :version, :deploy_gem

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
    self.host_with_port = host_with_port
    self.deploy_gem     = deploy_gem
    self.version        = version

    if delayed
      Delayed::Job.enqueue self, PRIORITIES[:web_hook]
    else
      perform
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

  def deployed_message
    "Successfully deployed webhook for #{what} to #{url}"
  end

  def failed_message
    "There was a problem deploying webhook for #{what} to #{url}"
  end

  def what
    if deploy_gem
      deploy_gem.name
    elsif rubygem
      rubygem.name
    else
      "all gems"
    end
  end

  def payload
    deploy_gem.payload(version).merge({
      'project_uri' => "http://#{host_with_port}/gems/#{deploy_gem.name}",
      'gem_uri'     => "http://#{host_with_port}/gems/#{version.full_name}.gem"
    }).to_json
  end

  def perform
    RestClient.post url, payload, 'Content-Type' => 'application/json'
    true
  rescue *(HTTP_ERRORS + [RestClient::Exception, SocketError]) => e
    increment! :failure_count unless new_record?
    false
  end

  def to_json(options = {})
    super(options.merge(:only => [:url, :failure_count]))
  end
end
