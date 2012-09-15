class VersionHistory < ActiveRecord::Base
  attr_accessible :count, :day, :version_id
  belongs_to :version
end
