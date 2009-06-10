class Requirement < ActiveRecord::Base
  belongs_to :version
  belongs_to :dependency
end
