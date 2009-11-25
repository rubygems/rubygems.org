class Dependency < ActiveRecord::Base
  belongs_to :rubygem
  belongs_to :version

  validates_presence_of  :requirements
  validates_inclusion_of :scope, :in => %w( development runtime )

  named_scope :development, { :conditions => { :scope => 'development' }}
  named_scope :runtime,     { :conditions => { :scope => 'runtime'     }}

  def self.create_from_gem_dependency!(dependency)
    return unless dependency.respond_to?(:name)

    rubygem = Rubygem.find_or_create_by_name(dependency.name)

    self.create!(
      :rubygem      => rubygem,
      :requirements => dependency.requirements_list.join(', '),
      :scope        => dependency.type.to_s
    )
  end

end
