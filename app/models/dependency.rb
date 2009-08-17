class Dependency < ActiveRecord::Base
  belongs_to :rubygem
  validates_presence_of :name
  attr_accessor :rubygem_name
  before_validation :link_rubygem

  protected
    def link_rubygem
      self.rubygem = Rubygem.find_or_initialize_by_name(self.rubygem_name)
    end
end
