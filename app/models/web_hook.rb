class WebHook < ActiveRecord::Base
  belongs_to :user
  belongs_to :rubygem

  named_scope :global, :conditions => {:rubygem_id => nil}
  named_scope :specific, :conditions => "rubygem_id is not null"

  GLOBAL_PATTERN = '*'

  attr_accessor :host_with_port, :version

  def validate_on_create
    if user && rubygem 
      if WebHook.exists?(:user_id    => user.id,
                         :rubygem_id => rubygem.id,
                         :url        => url)
        errors.add_to_base("A hook for #{url} has already been registered for #{rubygem.name}")
      end
    elsif user
      if WebHook.exists?(:user_id    => user.id,
                         :url        => url)
        errors.add_to_base("A global hook for #{url} has already been registered")
      end
    else
      errors.add_to_base("A user is required for this hook")
    end
  end

  def global?
    rubygem_id.blank?
  end

  def success_message
    what = global? ? "all gems" : rubygem.name
    "Successfully created webhook for #{what} to #{url}"
  end

  def payload
    rubygem.payload(version).merge({
      'project_uri' => "http://#{host_with_port}/gems/#{rubygem.name}",
      'gem_uri'     => "http://#{host_with_port}/gems/#{version.full_name}.gem"
    }).to_json
  end

  def perform
    RestClient.post url, payload, 'Content-Type' => 'application/json'
  rescue *(HTTP_ERRORS + [RestClient::Exception, SocketError]) => e
    increment! :failure_count
  end

  def to_json(options = {})
    super(options.merge(:only => [:url, :failure_count]))
  end
end
