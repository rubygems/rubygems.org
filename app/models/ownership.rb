class Ownership < ActiveRecord::Base
  belongs_to :rubygem
  belongs_to :user
end
