class Version < ActiveRecord::Base
  include Pacecar
  belongs_to :rubygem

  default_scope :order => 'created_at DESC'

  def to_s
    number
  end
end
