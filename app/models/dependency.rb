class Dependency < ActiveRecord::Base
  belongs_to :rubygem
  belongs_to :version

  validates_presence_of :requirements

  def self.create_from_gem_dependency!(dependency)
    rubygem = Rubygem.find_or_create_by_name(dependency.name)

    self.create!(
      :rubygem      => rubygem,
      :requirements => dependency.requirements_list.to_s
    )
  end

end
