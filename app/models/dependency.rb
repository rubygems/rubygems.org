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
    gem_list.map do |rubygem_name|
      versions = $redis.lrange(Rubygem.versions_key(rubygem_name), 0, -1)
      versions.map do |version|
        info = $redis.hgetall(Version.info_key(version))
        deps = $redis.lrange(Dependency.runtime_key(version), 0, -1)
        {
          :name         => info["name"],
          :number       => info["number"],
          :platform     => info["platform"],
          :dependencies => deps.map { |dep| dep.split(" ", 2) }
        }
      end
    end.flatten
  end

  def name
    rubygem.name
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

  private

  def use_gem_dependency
    if gem_dependency.class != Gem::Dependency
      errors.add :rubygem, "Please use Gem::Dependency to specify dependencies."
      false
    end
  end

  def use_existing_rubygem
    self.rubygem = Rubygem.find_by_name(gem_dependency.name)

    if rubygem.blank?
      errors[:base] << "Please specify dependencies that exist on #{I18n.t(:title)}: #{gem_dependency}"
      false
    end
  end

  def parse_gem_dependency
    reqs = gem_dependency.requirements_list.join(', ')
    self.requirements = reqs.gsub(/#<YAML::Syck::DefaultKey[^>]*>/, "=")

    self.scope = gem_dependency.type.to_s
  end

  def push_on_to_list
    $redis.lpush(Dependency.runtime_key(self.version.full_name), self.to_s) if self.scope == 'runtime'
  end
end
