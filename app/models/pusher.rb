require "digest/sha2"

class Pusher
  include TraceTagger
  include SemanticLogger::Loggable

  attr_reader :api_key, :owner, :spec, :spec_contents, :message, :code, :rubygem, :body, :version, :version_id, :size

  def initialize(api_key, body, remote_ip = "")
    @api_key = api_key
    @owner = api_key.owner
    @scoped_rubygem = api_key.rubygem

    @body = StringIO.new(body.read)
    @size = @body.size
    @remote_ip = remote_ip
  end

  def process
    trace("gemcutter.pusher.process", tags: { "gemcutter.api_key.owner" => owner.to_gid }) do
      pull_spec && find && authorize && verify_gem_scope && verify_mfa_requirement && validate && save
    end
  end

  def authorize
    (rubygem.pushable? && (api_key.user? || find_pending_trusted_publisher)) || owner.owns_gem?(rubygem) || notify_unauthorized
  end

  def verify_gem_scope
    return true unless @scoped_rubygem && rubygem != @scoped_rubygem

    notify("This API key cannot perform the specified action on this gem.", 403)
  end

  def verify_mfa_requirement
    (!api_key.user? || owner.mfa_enabled?) || !(version_mfa_required? || rubygem.metadata_mfa_required?) ||
      notify("Rubygem requires owners to enable MFA. You must enable MFA before pushing new version.", 403)
  end

  def validate
    unless validate_signature_exists?
      return notify("There was a problem saving your gem: \nYou have added cert_chain in gemspec but signature was empty", 403)
    end

    return notify("There was a problem saving your gem: #{rubygem.all_errors(version)}", 403) unless rubygem.valid? && version.valid?

    unless version.full_name == spec.original_name && version.gem_full_name == spec.full_name
      return notify("There was a problem saving your gem: the uploaded spec has malformed platform attributes", 409)
    end

    true
  end

  def save
    # Restructured so that if we fail to write the gem (ie, s3 is down)
    # can clean things up well.
    return notify("There was a problem saving your gem: #{rubygem.all_errors(version)}", 403) unless update
    trace("gemcutter.pusher.write_gem") do
      write_gem @body, @spec_contents
    end
  rescue ArgumentError => e
    @version&.destroy
    Rails.error.report(e, handled: true)
    notify("There was a problem saving your gem. #{e}", 400)
  rescue StandardError => e
    @version&.destroy
    Rails.error.report(e, handled: true)
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
    validate_spec && serialize_spec
  rescue StandardError => e
    notify <<~MSG, 422
      RubyGems.org cannot process this gem.
      Please try rebuilding it and installing it locally to make sure it's valid.
      Error:
      #{e.message}
    MSG
  end

  def find # rubocop:disable Metrics/AbcSize
    name = spec.name.to_s
    set_tag "gemcutter.rubygem.name", name

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
    spec_sha256 = Digest::SHA2.base64digest(spec_contents)

    @version = @rubygem.versions.new number: spec.version.to_s,
                                     platform: spec.original_platform.to_s,
                                     gem_platform: spec.platform.to_s,
                                     size: size,
                                     sha256: sha256,
                                     spec_sha256: spec_sha256,
                                     pusher: api_key.user,
                                     pusher_api_key: api_key,
                                     cert_chain: spec.cert_chain

    set_tags "gemcutter.rubygem.version" => @version.number, "gemcutter.rubygem.platform" => @version.platform
    log_pushing

    true
  end

  # Overridden so we don't get megabytes of the raw data printing out
  def inspect
    attrs = %i[@rubygem @owner @message @code].map do |attr|
      "#{attr}=#{instance_variable_get(attr).inspect}"
    end
    "<Pusher #{attrs.join(' ')}>"
  end

  private

  def after_write
    @version_id = version.id
    version.rubygem.push_notifiable_owners.each do |notified_user|
      Mailer.gem_pushed(owner, @version_id, notified_user.id).deliver_later
    end
    Indexer.perform_later
    UploadVersionsFileJob.perform_later
    UploadInfoFileJob.perform_later(rubygem_name: rubygem.name)
    UploadNamesFileJob.perform_later
    ReindexRubygemJob.perform_later(rubygem:)
    GemCachePurger.call(rubygem.name)
    StoreVersionContentsJob.perform_later(version:) if ld_variation(key: "gemcutter.pusher.store_version_contents", default: false)
    RackAttackReset.gem_push_backoff(@remote_ip, owner.to_gid) if @remote_ip.present?
    StatsD.increment "push.success"
  end

  def ld_variation(key:, default:)
    Rails.configuration.launch_darkly_client.variation(
      key, owner.ld_context, default
    )
  end

  def notify(message, code)
    logger.info { { message:, code:, owner: owner.to_gid, api_key: api_key&.id, rubygem: rubygem&.name, version: version&.full_name } }

    @message = message
    @code    = code
    false
  end

  def update
    rubygem.disown if rubygem.versions.indexed.count.zero?
    rubygem.update_attributes_from_gem_specification!(version, spec)

    if rubygem.unowned?
      case owner
      when User
        rubygem.create_ownership(owner)
      else
        pending_publisher = find_pending_trusted_publisher
        return notify_unauthorized if pending_publisher.blank?

        rubygem.transaction do
          logger.info { "Reifying pending publisher" }
          rubygem.create_ownership(pending_publisher.user)
          owner.rubygem_trusted_publishers.create!(rubygem: rubygem)
        end
      end
    end

    set_info_checksum

    true
  rescue ActiveRecord::RecordInvalid, ActiveRecord::Rollback, ActiveRecord::RecordNotUnique
    false
  end

  def set_info_checksum
    # TODO: may as well just upload this straight to S3...
    checksum = GemInfo.new(rubygem.name).info_checksum
    version.update_attribute :info_checksum, checksum
  end

  def republish_notification(version)
    if version.indexed?
      notify("Repushing of gem versions is not allowed.\n" \
             "Please bump the version number and push a new different release.\n" \
             "See also `gem yank` if you want to unpublish the bad release.", 409)
    else
      different_owner = "pushed by a previous owner of this gem " unless owner.owns_gem?(version.rubygem)
      notify("A yanked version #{different_owner}already exists (#{version.full_name}).\n" \
             "Repushing of gem versions is not allowed. Please use a new version and retry", 409)
    end
  end

  def notify_unauthorized
    if !api_key.user?
      notify("You are not allowed to push this gem.", 403)
    elsif rubygem.unconfirmed_ownership?(owner)
      notify("You do not have permission to push to this gem. " \
             "Please confirm the ownership by clicking on the confirmation link sent your email #{owner.email}", 403)
    else
      notify("You do not have permission to push to this gem. Ask an owner to add you with: gem owner #{rubygem.name} --add #{owner.email}", 403)
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

  # we validate that the version full_name == spec.original_name
  def write_gem(body, spec_contents)
    gem_path = "gems/#{@version.gem_file_name}"
    gem_contents = body.string

    spec_path = "quick/Marshal.4.8/#{@version.full_name}.gemspec.rz"

    # do all processing _before_ we upload anything to S3, so we lower the chances of orphaned files
    RubygemFs.instance.store(gem_path, gem_contents, checksum_sha256: version.sha256)
    RubygemFs.instance.store(spec_path, spec_contents, checksum_sha256: version.spec_sha256)

    Fastly.purge(path: gem_path)
    Fastly.purge(path: spec_path)
  end

  def log_pushing
    logger.info do
      # this is needed because the version can be invalid!
      version =
        begin
          @version.as_json
        rescue StandardError
          {
            number: @version.number,
            platform: @version.platform
          }
        end

      { message: "Pushing gem", version:, rubygem: @version.rubygem.name, pusher: owner.as_json }
    end
  end

  def validate_spec
    spec.send(:invalidate_memoized_attributes)

    spec = self.spec.dup

    cert_chain = spec.cert_chain

    spec.abbreviate
    spec.sanitize

    # make sure we validate the cert chain, which gets snipped in abbreviate
    spec.cert_chain = cert_chain

    # Silence warnings from the verification
    stream = StringIO.new
    policy = SpecificationPolicy.new(spec)
    policy.ui = Gem::StreamUI.new(stream, stream, stream, false)
    policy.validate(false)
  end

  def serialize_spec
    spec = self.spec.dup
    spec.abbreviate
    spec.sanitize
    @spec_contents = Gem.deflate(Marshal.dump(spec))
    true
  end

  def find_pending_trusted_publisher
    return unless owner.class.module_parent_name == "OIDC::TrustedPublisher"
    owner.pending_trusted_publishers.unexpired.rubygem_name_is(rubygem.name).first
  end
end
