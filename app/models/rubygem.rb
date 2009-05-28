class Rubygem < ActiveRecord::Base
  belongs_to :user
  has_many :versions
  has_many :dependencies

end
