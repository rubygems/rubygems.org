class WebHook < ActiveRecord::Base
  belongs_to :user
  belongs_to :rubygem

	named_scope :global, :conditions => {:rubygem_id => nil}
  
  GLOBAL_PATTERN = '*'

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
end
