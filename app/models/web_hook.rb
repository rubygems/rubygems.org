class WebHook < ActiveRecord::Base
  belongs_to :user
  
  ALL_GEMS_PATTERN = '*'

  def self.find_matching_by_gem_name(gem_name)
    self.find(:all, :conditions => [ "gem_name = ? OR gem_name = ?", gem_name, ALL_GEMS_PATTERN ])
  end

end
