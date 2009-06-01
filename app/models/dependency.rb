class Dependency < ActiveRecord::Base
  belongs_to :version
  validates_presence_of :name, :requirement

end
