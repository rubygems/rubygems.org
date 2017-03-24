class Announcement < ActiveRecord::Base
  def token
    "#{self.class.name.downcase}_#{created_at.iso8601}"
  end
end
