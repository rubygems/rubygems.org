class Gemcutter
  if Rails.env.development? || Rails.env.test?
    include Vault::FS
  else
    include Vault::S3
  end

  attr_reader :user, :spec, :message, :code, :rubygem, :body, :version, :version_id

  def initialize(user, body)
    @user = user
    @body = StringIO.new(body.read)
  end

  def process
    pull_spec && find && authorize && save
  end

  def authorize
    import? ||
    rubygem.pushable? ||
    rubygem.owned_by?(user) ||
    notify("You do not have permission to push to this gem.", 403)
  end

  def import?
    user.rubyforge_importer? && version.new_record?
  end

  def save
    if update
      write_gem
      @version_id = self.version.id
      Delayed::Job.enqueue self, 1
      notify("Successfully registered gem: #{self.version.to_title}", 200)
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
      rubygem.update_attributes_from_gem_specification!(version, spec)
      rubygem.create_ownership(user)
    end
    true
  rescue ActiveRecord::RecordInvalid, ActiveRecord::Rollback
    false
  end

  def pull_spec
    begin
      format = Gem::Format.from_io(self.body)
      @spec = format.spec
    rescue Exception => e
      notify("Gemcutter cannot process this gem.\n" + 
             "Please try rebuilding it and installing it locally to make sure it's valid.\n" +
             "Error:\n#{e.message}\n#{e.backtrace.join("\n")}", 422)
    end
  end

  def find
    @rubygem = Rubygem.find_or_initialize_by_name(self.spec.name)
    @version = @rubygem.find_or_initialize_version_from_spec(spec)
  end

  def self.server_path(*more)
    File.expand_path(File.join(File.dirname(__FILE__), '..', 'server', *more))
  end

  # Overridden so we don't get megabytes of the raw data printing out
  def inspect
    attrs = [:@rubygem, :@user, :@message, :@code].map { |attr| "#{attr}=#{instance_variable_get(attr) || 'nil'}" }
    "<Gemcutter #{attrs.join(' ')}>"
  end

  def self.indexer
    @indexer ||= 
      begin
        indexer = Gem::Indexer.new(Gemcutter.server_path, :build_legacy => false)
        def indexer.say(message) end
        indexer
      end
  end

  def specs_index
    Version.with_indexed.map(&:to_index)
  end

  def latest_index
    Version.latest.with_indexed.map(&:to_index)
  end

  def prerelease_index
    Version.prerelease.with_indexed.map(&:to_index)
  end

  def perform
    Version.update_all({:indexed => true}, {:id => self.version_id})
    update_index
  end

  def update_index
    upload("specs.4.8.gz", specs_index)
    upload("latest_specs.4.8.gz", latest_index)
    upload("prerelease_specs.4.8.gz", prerelease_index)
  end
end
