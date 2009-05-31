class Version < ActiveRecord::Base
  include Pacecar
  belongs_to :rubygem

  def to_s
    number
  end
end
