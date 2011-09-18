class Pusher
  include Vault

  attr_reader :user, :spec, :message, :code, :rubygem, :body, :version, :version_id

  def initialize(user, body, host_with_port=nil)
    @user = user
    @body = StringIO.new(body.read)
    @host_with_port = host_with_port
  end

  def process
    pull_spec && find && authorize && save
  end

  def authorize
    rubygem.pushable? ||
    rubygem.owned_by?(user) ||
    notify("You do not have permission to push to this gem.", 403)
  end

  def save
    if update
      write_gem
      after_write
      notify("Successfully registered gem: #{version.to_title}", 200)
    else
      notify("There was a problem saving your gem: #{rubygem.all_errors(version)}", 403)
    end
  end

  def after_write
    @version_id = version.id
    Delayed::Job.enqueue self, :priority => PRIORITIES[:push]
    enqueue_web_hook_jobs
  end

  def notify(message, code)
    @message = message
    @code    = code
    false
  end

  def update
    rubygem.update_attributes_from_gem_specification!(version, spec)
    rubygem.create_ownership(user) unless version.new_record?
    true
  rescue ActiveRecord::RecordInvalid, ActiveRecord::Rollback
    false
  end

  def pull_spec
    Gem::Package.open body, "r", nil do |pkg|
      @spec = pkg.metadata
      return true
    end

    false
  rescue Gem::Package::FormatError
    notify("RubyGems.org cannot process this gem.\nPlease try rebuilding it" +
           " and installing it locally to make sure it's valid.", 422)
  rescue Exception => e
    notify("RubyGems.org cannot process this gem.\nPlease try rebuilding it" +
           " and installing it locally to make sure it's valid.\n" +
           "Error:\n#{e.message}\n#{e.backtrace.join("\n")}", 422)
  end

  def find
    @rubygem = Rubygem.find_or_initialize_by_name(spec.name)
    @version = @rubygem.find_or_initialize_version_from_spec(spec)

    if @version.new_record?
      true
    else
      notify("Repushing of gem versions is not allowed.\n" +
             "Please use `gem yank` to remove bad gem releases.", 409)
    end
  end

  def self.server_path(*more)
    File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'server', *more))
  end

  # Overridden so we don't get megabytes of the raw data printing out
  def inspect
    attrs = [:@rubygem, :@user, :@message, :@code].map { |attr| "#{attr}=#{instance_variable_get(attr) || 'nil'}" }
    "<Gemcutter #{attrs.join(' ')}>"
  end

  def minimize_specs(data)
    names     = Hash.new { |h,k| h[k] = k }
    versions  = Hash.new { |h,k| h[k] = Gem::Version.new(k) }
    platforms = Hash.new { |h,k| h[k] = k }

    data.each do |row|
      row[0] = names[row[0]]
      row[1] = versions[row[1].strip]
      row[2] = platforms[row[2]]
    end

    data
  end

  def specs_index
    minimize_specs Version.rows_for_index
  end

  def latest_index
    minimize_specs Version.rows_for_latest_index
  end

  def prerelease_index
    minimize_specs Version.rows_for_prerelease_index
  end

  def perform
    log "Updating the index"
    update_index
    log "Finished updating the index"
  end

  def update_index
    upload("specs.4.8.gz", specs_index)
    log "Uploaded all specs index"
    upload("latest_specs.4.8.gz", latest_index)
    log "Uploaded latest specs index"
    upload("prerelease_specs.4.8.gz", prerelease_index)
    log "Uploaded prerelease specs index"
  end

  def enqueue_web_hook_jobs
    jobs = rubygem.web_hooks + WebHook.global
    jobs.each do |job|
      job.fire(@host_with_port, rubygem, version)
    end
  end

  def self.indexer
    @indexer ||=
      begin
        indexer = Gem::Indexer.new(server_path, :build_legacy => false)
        def indexer.say(message) end
        indexer
      end
  end

  def log(message)
    Rails.logger.info "[GEMCUTTER:#{Time.now}] #{message}"
  end
end
