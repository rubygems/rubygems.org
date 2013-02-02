class Pusher
  attr_reader :user, :spec, :message, :code, :rubygem, :body, :version, :version_id
  attr_accessor :bundler_api_url

  def initialize(user, body, host_with_port=nil)
    @user = user
    @body = StringIO.new(body.read)
    @indexer = Indexer.new
    @host_with_port = host_with_port
    @bundler_token = ENV['BUNDLER_TOKEN'] || "tokenmeaway"
    @bundler_api_url = ENV['BUNDLER_API_URL']
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
      @indexer.write_gem @body, @spec
      after_write
      notify("Successfully registered gem: #{version.to_title}", 200)
    else
      notify("There was a problem saving your gem: #{rubygem.all_errors(version)}", 403)
    end
  end

  def pull_spec
    Gem::Package.open body, "r", nil do |pkg|
      @spec = pkg.metadata
      return true
    end

    false
  rescue Psych::WhitelistException => e
    Rails.logger.info "Attempted YAML metadata exploit: #{e}"
    notify("RubyGems.org cannot process this gem.\nThe metadata is invalid.\n#{e}", 422)
  rescue Gem::Package::FormatError
    notify("RubyGems.org cannot process this gem.\nPlease try rebuilding it" +
           " and installing it locally to make sure it's valid.", 422)
  rescue Exception => e
    notify("RubyGems.org cannot process this gem.\nPlease try rebuilding it" +
           " and installing it locally to make sure it's valid.\n" +
           "Error:\n#{e.message}\n#{e.backtrace.join("\n")}", 422)
  end

  def find
    @rubygem = Rubygem.find_or_initialize_by_name(spec.name.to_s)
    @version = @rubygem.find_or_initialize_version_from_spec(spec)

    if @version.new_record?
      true
    else
      notify("Repushing of gem versions is not allowed.\n" +
             "Please use `gem yank` to remove bad gem releases.", 409)
    end
  end

  # Overridden so we don't get megabytes of the raw data printing out
  def inspect
    attrs = [:@rubygem, :@user, :@message, :@code].map { |attr| "#{attr}=#{instance_variable_get(attr) || 'nil'}" }
    "<Pusher #{attrs.join(' ')}>"
  end

  def update_remote_bundler_api(to=RestClient)
    return unless @bundler_api_url

    json = %Q!{ "name": "#{spec.name}", "version": "#{spec.version}", "platform": "#{spec.platform}", "prerelease": #{spec.version.prerelease? ? 'true' : 'false'}, "rubygems_token": "#{@bundler_token}"}!

    begin
      timeout(5) do
        to.post @bundler_api_url,
                        json,
                        :timeout        => 5,
                        :open_timeout   => 5,
                        'Content-Type'  => 'application/json'
      end
    rescue StandardError, Interrupt
      false
    end
  end
  private

  def after_write
    @version_id = version.id
    Delayed::Job.enqueue Indexer.new, :priority => PRIORITIES[:push]
    enqueue_web_hook_jobs
    update_remote_bundler_api
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

  def self.server_path(*more)
    File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'server', *more))
  end

  def enqueue_web_hook_jobs
    jobs = rubygem.web_hooks + WebHook.global
    jobs.each do |job|
      job.fire(@host_with_port, rubygem, version)
    end
  end
end
