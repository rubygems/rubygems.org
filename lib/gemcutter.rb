class Gemcutter
  if Rails.env.production?
    include Vault::S3
  else
    include Vault::FS
  end

  attr_reader :user, :data, :spec, :message, :code, :rubygem

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
      @message = "You do not have permission to push to this gem."
      @code    = 403
      false
    end
  end

  def save
    build
    if rubygem.save
      store
      notify("Successfully registered gem: #{rubygem}", 200)
    else
      notify("Gemcutter cannot process this gem. Please try rebuilding it and installing it locally to make sure it's valid.", 403)
    end
  end

  def notify(message, code)
    @message = message
    @code    = code
    false
  end

  def build
    rubygem.build_name(spec.name)
    if spec.platform.to_s == "ruby"
      number = spec.version.to_s
    else
      number = "#{spec.version}-#{spec.platform}"
    end

    rubygem.build_version(
      :authors           => spec.authors.join(", "),
      :description       => spec.description,
      :summary           => spec.summary,
      :rubyforge_project => spec.rubyforge_project,
      :created_at        => spec.date,
      :number            => number)
    rubygem.build_dependencies(spec.dependencies)
    rubygem.build_links(spec.homepage)
    rubygem.build_ownership(user) if user
    true
  end

  def pull_spec
    begin
      format = Gem::Format.from_io(StringIO.new(data.string))
      @spec = format.spec
    rescue Exception => e
      notify("Gemcutter cannot process this gem. Please try rebuilding it and installing it locally to make sure it's valid.", 422)
    end
  end

  def find
    @rubygem = Rubygem.find_or_initialize_by_name(self.spec.name)
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
