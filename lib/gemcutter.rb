class Gemcutter
  if Rails.env.development? || Rails.env.test?
    include Vault::FS
  else
    include Vault::S3
  end

  attr_reader :user, :spec, :message, :code, :rubygem, :raw_data, :body

  def initialize(user, body)
    @user = user
    @body = body
  end

  def process
    pull_spec and find and authorize and save
  end

  def authorize
    if rubygem.pushable? || rubygem.owned_by?(@user)
      true
    else
      @message = "You do not have permission to push to this gem."
      @code    = 403
      false
    end
  end

  def save
    if update
      Delayed::Job.enqueue self
      notify("Successfully registered gem: #{rubygem.versions.latest.to_title}", 200)
    else
      notify("There was a problem saving your gem: #{rubygem.errors.full_messages}", 403)
    end
  end

  def notify(message, code)
    @message = message
    @code    = code
    false
  end

  def update
    Rubygem.transaction do
      rubygem.build_ownership(user) if user
      rubygem.save!
      rubygem.update_attributes_from_gem_specification!(spec)
    end
    true
  rescue ActiveRecord::RecordInvalid, ActiveRecord::Rollback
    false
  end

  def pull_spec
    begin
      @raw_data = body.read
      format = Gem::Format.from_io(StringIO.new(self.raw_data))
      @spec = format.spec
    rescue Exception => e
      notify("Gemcutter cannot process this gem.\n" + 
             "Please try rebuilding it and installing it locally to make sure it's valid.\n" +
             "Error:\n#{e.message}", 422)
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
