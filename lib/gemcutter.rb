class Gemcutter
  attr_reader :user, :data, :spec, :error_message, :error_code, :rubygem

  def initialize(user, data)
    @user = user
    @data = data
  end

  def process
    pull_spec and find and authorize and save
  end

  def authorize
    if rubygem.new_record? || rubygem.owned_by?(@user)
      true
    else
      @error_message = "You do not have permission to push to this gem."
      @error_code    = 403
      false
    end
  end

  def save
    build
    if rubygem.save
      store
    else
    end
  end

  def build
    rubygem.build_name(spec.name)
    rubygem.build_version(
      :authors           => spec.authors.join(", "),
      :description       => spec.description,
      :summary           => spec.summary,
      :rubyforge_project => spec.rubyforge_project,
      :created_at        => spec.date,
      :number            => spec.version.to_s)
    rubygem.build_dependencies(spec.dependencies)
    rubygem.build_links(spec.homepage)
  end

  def store
  end

  def pull_spec
    begin
      format = Gem::Format.from_io(data)
      @spec = format.spec
    rescue Exception => e
      @error_message = "Gemcutter cannot process this gem. Please try rebuilding it and installing it locally to make sure it's valid."
      @error_code = 422
      false
    end
  end

  def find
    @rubygem = Rubygem.find_or_initialize_by_name(@spec.name)
  end

  def self.server_path(*more)
    File.expand_path(File.join(File.dirname(__FILE__), '..', 'server', *more))
  end

  def self.indexer
    indexer = Gem::Indexer.new(Gemcutter.server_path, :build_legacy => false)
    def indexer.say(message) end
    indexer
  end
end
