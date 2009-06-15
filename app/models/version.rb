class Version < ActiveRecord::Base
  include Pacecar
  belongs_to :rubygem, :counter_cache => true
  has_many :requirements, :dependent => :destroy
  has_many :dependencies, :through => :requirements, :dependent => :destroy

  def to_s
    number
  end
end
