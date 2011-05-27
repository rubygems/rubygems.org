class Pusher
  include Vault
  include NewRelic::Agent::Instrumentation::ControllerInstrumentation

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
    # Use Gem::Package instead of Gem::Format so that we don't have
    # to reread and decode the body of the gem since we only want
    # the metadata.
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
    versions  = Hash.new { |h,k| h[k] = k }
    platforms = Hash.new { |h,k| h[k] = k }

    data.each do |row|
      row[0] = names[row[0]]
      row[1] = versions[Gem::Version.new(row[1])]
      row[2] = platforms[row[2]]
    end

    data
  end

  def specs_index
    minimize_specs Version.rows_for_index
  end

  def slow_specs_index
    vers = Version.indexed.select('rubygems.name, versions.number, versions.platform').from("versions").joins(:rubygem).order("rubygems.name asc, position desc")
    vers.map { |v| [v.name, Gem::Version.new(v.number), v.platform ] }
  end

  def very_slow_specs_index
    Version.with_indexed(true).map(&:to_index)
  end

  def latest_index
    minimize_specs Version.rows_for_latest_index
  end

  def slow_latest_index
    Version.latest.with_indexed.map(&:to_index)
  end

  def prerelease_index
    minimize_specs Version.rows_for_prerelease_index
  end

  def slow_prerelease_index
    Version.prerelease.with_indexed(true).map(&:to_index)
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

  add_transaction_tracer :perform, :category => :task
  add_transaction_tracer :specs_index, :category => :task
  add_transaction_tracer :latest_index, :category => :task
  add_transaction_tracer :prerelease_index, :category => :task
end
