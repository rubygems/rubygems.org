require "digest/sha2"

class Pusher
  attr_reader :user, :spec, :message, :code, :rubygem, :body, :version, :version_id, :size

  def initialize(user, body, remote_ip = "")
    @user = user
    @body = StringIO.new(body.read)
    @size = @body.size
    @indexer = Indexer.new
    @remote_ip = remote_ip
  end

  def process
    pull_spec && find && authorize && verify_mfa_requirement && validate && save
  end

  def authorize
    rubygem.pushable? || rubygem.owned_by?(user) || notify_unauthorized
  end

  def verify_mfa_requirement
    user.mfa_enabled? || !(version_mfa_required? || rubygem.mfa_required?) ||
      notify("Rubygem requires owners to enable MFA. You must enable MFA before pushing new version.", 403)
  end

  def validate
    signature_missing = "There was a problem saving your gem: \nYou have added cert_chain in gemspec but signature was empty"

    return notify(signature_missing, 403) unless validate_signature_exists?
    (rubygem.valid? && version.valid?) || notify("There was a problem saving your gem: #{rubygem.all_errors(version)}", 403)
  end

  def save
    # Restructured so that if we fail to write the gem (ie, s3 is down)
    # can clean things up well.
    return notify("There was a problem saving your gem: #{rubygem.all_errors(version)}", 403) unless update
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
    after_write
    notify("Successfully registered gem: #{version.to_title}", 200)
    true
  end

  def pull_spec
    package = Gem::Package.new(body, gem_security_policy)
    @spec = package.spec
    @files = package.files
  rescue StandardError => e
    notify <<-MSG.strip_heredoc, 422
      RubyGems.org cannot process this gem.
      Please try rebuilding it and installing it locally to make sure it's valid.
      Error:
      #{e.message}
    MSG
  end

  def find
    name = spec.name.to_s

    @rubygem = Rubygem.name_is(name).first || Rubygem.new(name: name)

    unless @rubygem.new_record?
      if (version = @rubygem.find_version_from_spec spec)
        republish_notification(version)
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
                                     canonical_number: spec.version.canonical_segments.join("."),
                                     platform: spec.original_platform.to_s,
                                     size: size,
                                     sha256: sha256,
                                     pusher: user,
                                     cert_chain: spec.cert_chain

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
    version.rubygem.push_notifiable_owners.each do |notified_user|
      Mailer.delay.gem_pushed(user.id, @version_id, notified_user.id)
    end
    Delayed::Job.enqueue Indexer.new, priority: PRIORITIES[:push]
    rubygem.delay.index_document
    GemCachePurger.call(rubygem.name)
    RackAttackReset.gem_push_backoff(@remote_ip) if @remote_ip.present?
    StatsD.increment "push.success"
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
  rescue ActiveRecord::RecordInvalid, ActiveRecord::Rollback, ActiveRecord::RecordNotUnique
    false
  end

  def set_info_checksum
    checksum = GemInfo.new(rubygem.name).info_checksum
    version.update_attribute :info_checksum, checksum
  end

  def republish_notification(version)
    if version.indexed?
      notify("Repushing of gem versions is not allowed.\n" \
             "Please use `gem yank` to remove bad gem releases.", 409)
    else
      different_owner = "pushed by a previous owner of this gem " unless version.rubygem.owners.include?(@user)
      notify("A yanked version #{different_owner}already exists (#{version.full_name}).\n" \
             "Repushing of gem versions is not allowed. Please use a new version and retry", 409)
    end
  end

  def notify_unauthorized
    if rubygem.unconfirmed_ownership?(user)
      notify("You do not have permission to push to this gem. "\
             "Please confirm the ownership by clicking on the confirmation link sent your email #{user.email}", 403)
    else
      notify("You do not have permission to push to this gem. Ask an owner to add you with: gem owner #{rubygem.name} --add #{user.email}", 403)
    end
  end

  def gem_security_policy
    @gem_security_policy ||= begin
      # Verify that the gem signatures match the certificate chain (if present)
      policy = PushPolicy.dup
      # Silence warnings from the verification
      stream = StringIO.new
      policy.ui = Gem::StreamUI.new(stream, stream, stream, false)
      policy
    end
  end

  def validate_signature_exists?
    return true if @spec.cert_chain.empty?

    signatures = @files.select { |file| file[/\.sig$/] }

    expected_signatures = %w[metadata.gz.sig data.tar.gz.sig checksums.yaml.gz.sig]
    expected_signatures.difference(signatures).empty?
  end

  def version_mfa_required?
    ActiveRecord::Type::Boolean.new.cast(spec.metadata["rubygems_mfa_required"])
  end
end
