class Dependency < ActiveRecord::Base
  belongs_to :rubygem
  validates_presence_of :name, :requirement

end
