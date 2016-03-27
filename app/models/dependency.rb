class Dependency < ActiveRecord::Base
  belongs_to :rubygem
  belongs_to :version

  before_validation :use_gem_dependency,
    :use_existing_rubygem,
    :parse_gem_dependency
  after_create :push_on_to_list

  validates :requirements, presence: true
  validates :scope,        inclusion: { in: %w(development runtime) }

  attr_accessor :gem_dependency

  def self.unresolved(rubygem)
    where(unresolved_name: nil, rubygem_id: rubygem.id)
  end

  def self.mark_unresolved_for(rubygem)
    unresolved(rubygem).update_all(unresolved_name: rubygem.name,
                                   rubygem_id: nil)
  end

  def self.development
    where(scope: 'development')
  end

  def self.runtime
    where(scope: 'runtime')
  end

  def self.runtime_key(full_name)
    "rd:#{full_name}"
  end

  def name
    unresolved_name || rubygem.try(:name)
  end

  def payload
    {
      'name'         => name,
      'requirements' => clean_requirements
    }
  end

  def as_json(*)
    payload
  end

  def to_xml(options = {})
    payload.to_xml(options.merge(root: 'dependency'))
  end

  def to_yaml(*args)
    payload.to_yaml(*args)
  end

  def encode_with(coder)
    coder.tag = nil
    coder.implicit = true
    coder.map = payload
  end

  def to_s
    "#{name} #{clean_requirements}"
  end

  def clean_requirements(reqs = requirements)
    reqs.gsub(/#<YAML::Syck::DefaultKey[^>]*>/, "=")
  end

  def update_resolved(rubygem)
    self.rubygem = rubygem
    self.unresolved_name = nil
    save!
  end

  private

  def use_gem_dependency
    return if rubygem

    if gem_dependency.class != Gem::Dependency
      errors.add :rubygem, "Please use Gem::Dependency to specify dependencies."
      return false
    end

    if gem_dependency.name.empty?
      errors.add :rubygem, "Blank is not a valid dependency name"
      return false
    end

    true
  end

  def use_existing_rubygem
    return if rubygem

    self.rubygem = Rubygem.find_by_name(gem_dependency.name)

    self.unresolved_name = gem_dependency.name unless rubygem

    true
  end

  def parse_gem_dependency
    return if requirements

    reqs = gem_dependency.requirements_list.join(', ')
    self.requirements = clean_requirements(reqs)

    self.scope = gem_dependency.type.to_s
  end

  def push_on_to_list
    Redis.current.lpush(Dependency.runtime_key(version.full_name), to_s) if scope == 'runtime'
  end
end
