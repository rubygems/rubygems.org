class Version < ActiveRecord::Base
  include Pacecar
  belongs_to :rubygem
  has_many :dependencies, :dependent => :destroy

  def to_s
    number
  end
end
