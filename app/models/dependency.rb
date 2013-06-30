class Dependency < ActiveRecord::Base
  LIMIT = 250

  belongs_to :rubygem
  belongs_to :version

  before_validation :use_gem_dependency,
                    :use_existing_rubygem,
                    :parse_gem_dependency
  after_create      :push_on_to_list

  validates :requirements, :presence => true
  validates :scope,        :inclusion => {:in => %w(development runtime)}

  attr_accessor :gem_dependency

  def self.mark_unresolved_for(rubygem)
    where(:unresolved_name => nil, :rubygem_id => rubygem.id).update_all(:unresolved_name => rubygem.name, :rubygem_id => nil)
  end

  def self.development
    where(:scope => 'development')
  end

  def self.runtime
    where(:scope => 'runtime')
  end

  def self.runtime_key(full_name)
    "rd:#{full_name}"
  end

  # rails,rack,bundler
  def self.for(gem_list)
    versions = $redis.pipelined do
      gem_list.each do |rubygem_name|
        $redis.lrange(Rubygem.versions_key(rubygem_name), 0, -1)
      end
    end || []
    versions.flatten!

    return [] if versions.blank?

    data = $redis.pipelined do
      versions.each do |version|
        $redis.hvals(Version.info_key(version))
        $redis.lrange(Dependency.runtime_key(version), 0, -1)
      end
    end

    data.in_groups_of(2).map do |(name, number, platform), deps|
      {
        :name         => name,
        :number       => number,
        :platform     => platform,
        :dependencies => deps.map { |dep| dep.split(" ", 2) }
      }
    end
  end

  def name
    unresolved_name || rubygem.name
  end

  def payload
    {
      'name'         => name,
      'requirements' => clean_requirements
    }
  end

  def as_json(options={})
    payload
  end

  def to_xml(options={})
    payload.to_xml(options.merge(:root => 'dependency'))
  end

  def to_yaml(*args)
    payload.to_yaml(*args)
  end

  def encode_with(coder)
    coder.tag, coder.implicit, coder.map = nil, true, payload
  end

  def to_s
    "#{name} #{clean_requirements}"
  end

  def clean_requirements
    requirements.gsub /#<YAML::Syck::DefaultKey[^>]*>/, "="
  end

  def update_resolved(rubygem)
    self.rubygem = rubygem
    self.unresolved_name = nil
    save!
  end

  private

  def use_gem_dependency
    return if self.rubygem

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
    return if self.rubygem

    unless self.rubygem = Rubygem.find_by_name(gem_dependency.name)
      self.unresolved_name = gem_dependency.name
    end

    true
  end

  def parse_gem_dependency
    return if self.requirements

    reqs = gem_dependency.requirements_list.join(', ')
    self.requirements = reqs.gsub(/#<YAML::Syck::DefaultKey[^>]*>/, "=")

    self.scope = gem_dependency.type.to_s
  end

  def push_on_to_list
    $redis.lpush(Dependency.runtime_key(self.version.full_name), self.to_s) if self.scope == 'runtime'
  end
end
