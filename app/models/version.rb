class Version < ActiveRecord::Base
  include Pacecar
  belongs_to :rubygem, :counter_cache => true
  has_many :requirements, :dependent => :destroy
  has_many :dependencies, :through => :requirements, :dependent => :destroy
  validates_format_of :number, :with => /^[\w\.\-_]+$/

  def to_s
    number
  end
end
