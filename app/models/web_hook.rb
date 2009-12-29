class WebHook < ActiveRecord::Base
  belongs_to :user
  belongs_to :rubygem

  named_scope :global, :conditions => {:rubygem_id => nil}
  
  GLOBAL_PATTERN = '*'

  attr_accessor :host_with_port

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

  def payload
    rubygem.payload.merge({
      'project_uri' => "http://#{host_with_port}/gems/#{rubygem.name}",
      'gem_uri'     => "http://#{host_with_port}/gems/#{rubygem.versions.latest.full_name}.gem"
    }).to_json
  end

  def perform
    RestClient.post url, payload, 'Content-Type' => 'application/json'
  rescue *(HTTP_ERRORS + [RestClient::Exception, SocketError]) => e
    increment! :failure_count
  end
end
