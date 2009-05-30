class Version < ActiveRecord::Base
  belongs_to :rubygem

  default_scope :order => 'created_at DESC'
end
