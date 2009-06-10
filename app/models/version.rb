class Version < ActiveRecord::Base
  include Pacecar
  belongs_to :rubygem
  has_many :requirements, :dependent => :destroy
  has_many :dependencies, :through => :requirements

  def to_s
    number
  end
end
