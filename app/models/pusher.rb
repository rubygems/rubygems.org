require 'digest/sha2'

class Pusher
  attr_reader :user, :spec, :message, :code, :rubygem, :body, :version, :version_id, :size

  def initialize(user, body, protocol = nil, host_with_port = nil)
    @user = user
    @body = StringIO.new(body.read)
    @size = @body.size
    @indexer = Indexer.new
    @protocol = protocol
    @host_with_port = host_with_port
  end

  def process
    pull_spec && find && authorize && validate && save
  end

  def authorize
    rubygem.pushable? ||
      rubygem.owned_by?(user) ||
      notify("You do not have permission to push to this gem. Ask an owner to add you with: gem owner #{rubygem.name} --add #{user.email}", 403)
  end

  def validate
    (rubygem.valid? && version.valid?) || notify("There was a problem saving your gem: #{rubygem.all_errors(version)}", 403)
  end

  def save
    # Restructured so that if we fail to write the gem (ie, s3 is down)
    # can clean things up well.

    @indexer.write_gem @body, @spec
  rescue ArgumentError => e
    @version.destroy
    Honeybadger.notify(e)
    notify("There was a problem saving your gem. #{e}", 400)
  rescue StandardError => e
    @version.destroy
    Honeybadger.notify(e)
    notify("There was a problem saving your gem. Please try again.", 500)
  else
    if update
      after_write
      notify("Successfully registered gem: #{version.to_title}", 200)
    else
      notify("There was a problem saving your gem: #{rubygem.all_errors(version)}", 403)
    end
  end

  def pull_spec
    @spec = Gem::Package.new(body).spec
  rescue StandardError => error
    notify <<-MSG.strip_heredoc, 422
      RubyGems.org cannot process this gem.
      Please try rebuilding it and installing it locally to make sure it's valid.
      Error:
      #{error.message}
    MSG
  end

  def find
    name = spec.name.to_s

    @rubygem = Rubygem.name_is(name).first || Rubygem.new(name: name)

    unless @rubygem.new_record?
      if @rubygem.find_version_from_spec(spec)
        notify("Repushing of gem versions is not allowed.\n" \
               "Please use `gem yank` to remove bad gem releases.", 409)

        return false
      end

      if @rubygem.name != name && @rubygem.indexed_versions?
        return notify("Unable to change case of gem name with indexed versions\n" \
                      "Please delete all versions first with `gem yank`.", 409)
      end
    end

    # Update the name to reflect a valid case change
    @rubygem.name = name

    sha256 = Digest::SHA2.base64digest(body.string)

    @version = @rubygem.versions.new number: spec.version.to_s,
                                     platform: spec.original_platform.to_s,
                                     size: size,
                                     sha256: sha256

    true
  end

  # Overridden so we don't get megabytes of the raw data printing out
  def inspect
    attrs = %i[@rubygem @user @message @code].map do |attr|
      "#{attr}=#{instance_variable_get(attr).inspect}"
    end
    "<Pusher #{attrs.join(' ')}>"
  end

  private

  def after_write
    @version_id = version.id
    Delayed::Job.enqueue Indexer.new, priority: PRIORITIES[:push]
    rubygem.delay.index_document
    GemCachePurger.call(rubygem.name)
    enqueue_web_hook_jobs
    StatsD.increment 'push.success'
  end

  def notify(message, code)
    @message = message
    @code    = code
    false
  end

  def update
    rubygem.disown if rubygem.versions.indexed.count.zero?
    rubygem.update_attributes_from_gem_specification!(version, spec)
    rubygem.create_ownership(user)
    set_info_checksum

    true
  rescue ActiveRecord::RecordInvalid, ActiveRecord::Rollback
    false
  end

  def enqueue_web_hook_jobs
    jobs = rubygem.web_hooks + WebHook.global
    jobs.each do |job|
      job.fire(@protocol, @host_with_port, rubygem, version)
    end
  end

  def set_info_checksum
    checksum = GemInfo.new(rubygem.name).info_checksum
    version.update_attribute :info_checksum, checksum
  end
end
