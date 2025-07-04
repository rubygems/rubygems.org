require "digest/sha2"

class Pusher
  include TraceTagger
  include SemanticLogger::Loggable

  attr_reader :api_key, :spec, :spec_contents, :message, :code, :rubygem, :body, :version, :version_id, :size, :attestations

  delegate :owner, to: :api_key

  def initialize(api_key, body, request: nil, attestations: nil)
    @api_key = api_key
    @scoped_rubygem = api_key.rubygem

    @body = StringIO.new(body.read)
    @attestations = attestations

    @size = @body.size
    @request = request
  end

  def process
    trace("gemcutter.pusher.process", tags: { "gemcutter.api_key.owner" => owner.to_gid }) do
      pull_spec &&
        find &&
        authorize &&
        verify_gem_scope &&
        verify_mfa_requirement &&
        validate &&
        save
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

    return unless verify_sigstore

    true
  end

  def save
    # Restructured so that if we fail to write the gem (ie, s3 is down)
    # can clean things up well.
    unless update
      return false if message
      return notify("There was a problem saving your gem: #{rubygem.all_errors(version)}", 403)
    end
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
    # ensure the body can't be treated as a file path
    package_source = Gem::Package::IOSource.new(body)
    package = Gem::Package.new(package_source, gem_security_policy)
    @spec = package.spec
    @files = package.files
    validate_spec && serialize_spec
  rescue Psych::AliasesNotEnabled
    notify <<~MSG, 422
      RubyGems.org cannot process this gem.
      Pushing gems where there are aliases in the YAML gemspec is no longer supported.
      Ensure you are using a recent version of RubyGems to build the gem by running
      `gem update --system` and then try pushing again.
    MSG
  rescue Gem::Exception, Psych::DisallowedClass, ArgumentError => e
    notify <<~MSG, 422
      RubyGems.org cannot process this gem.
      Please try rebuilding it and installing it locally to make sure it's valid.
      Error:
      #{e.message}
    MSG
  rescue StandardError
    # Ensure arbitrary exceptions are not leaked to the client
    notify <<~MSG, 422
      RubyGems.org cannot process this gem.
      Please try rebuilding it and installing it locally to make sure it's valid.
    MSG
  end

  def find # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    name = spec.name.to_s
    set_tag "gemcutter.rubygem.name", name

    @rubygem = Rubygem.name_is(name).first || Rubygem.new(name: name)

    sha256 = Digest::SHA2.base64digest(body.string)
    spec_sha256 = Digest::SHA2.base64digest(spec_contents)

    version = @rubygem.versions
      .create_with(indexed: false, cert_chain: spec.cert_chain)
      .find_or_initialize_by(
        number: spec.version.to_s,
        platform: spec.original_platform.to_s,
        gem_platform: spec.platform.to_s,
        size: size,
        sha256: sha256,
        spec_sha256: spec_sha256,
        pusher: api_key.user,
        pusher_api_key: api_key
      )

    unless @rubygem.new_record?
      # Return success for idempotent pushes
      return notify("Gem was already pushed: #{version.to_title}", 200) if version.indexed?

      # If the gem is yanked, we can't repush it
      # Additionally, we don't allow overwriting existing versions
      if (existing = @rubygem.versions.find_by(number: version.number, platform: version.platform))
        return republish_notification(existing)
      end

      if @rubygem.name != name && @rubygem.indexed_versions?
        return notify("Unable to change case of gem name with indexed versions\n" \
                      "Please delete all versions first with `gem yank`.", 409)
      end
    end

    # Update the name to reflect a valid case change
    @rubygem.name = name
    @version = version

    set_tags "gemcutter.rubygem.version" => @version.number, "gemcutter.rubygem.platform" => @version.platform
    log_pushing

    true
  end

  # Overridden so we don't get megabytes of the raw data printing out
  def inspect
    attrs = { :@rubygem => @rubygem, :@owner => owner, :@message => @message, :@code => @code }.map do |attr, value|
      "#{attr}=#{value.inspect}"
    end
    "<Pusher #{attrs.join(' ')}>"
  end

  def verify_sigstore
    return true if attestations.blank?
    return notify("Pushing with an attestation requires trusted publishing", 400) unless api_key.trusted_publisher?

    policy = api_key.owner.to_sigstore_identity_policy

    artifact = Sigstore::Verification::V1::Artifact.new
    artifact.artifact = body.string

    attestations.each do |attestation|
      bundle = Sigstore::Bundle::V1::Bundle.decode_json_hash(attestation, registry: Sigstore::REGISTRY)

      verification_input = Sigstore::Verification::V1::Input.new
      verification_input.artifact = artifact
      verification_input.bundle = bundle
      input = Sigstore::VerificationInput.new(verification_input)
      sigstore_verification = sigstore_verifier.verify(input:, policy:, offline: true)
      logger.info do
        { message: "verifying sigstore bundles", sigstore_verification: sigstore_verification, policy: policy }
      end

      return notify("Attestation verification failed:\n#{sigstore_verification.reason}", 422) unless sigstore_verification.verified?
      return notify("Must provide at least v0.3 bundles", 422) unless input.sbundle.bundle_type >= Sigstore::BundleType::BUNDLE_0_3

      @version.attestations << Attestation.new(body: bundle, media_type: bundle.media_type)
    end

    true
  rescue Sigstore::Error => e
    notify <<~MSG, 422
      Error verifying sigstore attestation:
      #{e.message}
    MSG
  end

  private

  def after_write
    GemCachePurger.call(rubygem.name)
    RackAttackReset.gem_push_backoff(@request.remote_ip, owner.to_gid) if @request&.remote_ip.present?
    AfterVersionWriteJob.new(version:).perform(version:)
    StatsD.increment "push.success"
    Rstuf::AddJob.perform_later(version:)
  end

  def notify(message, code) # rubocop:disable Naming/PredicateMethod
    logger.info { { message:, code:, owner: owner.to_gid, api_key: api_key&.id, rubygem: rubygem&.name, version: version&.full_name } }

    @message = message
    @code    = code
    false
  end

  def update
    rubygem.disown if rubygem.versions.indexed.none?
    rubygem.update_attributes_from_gem_specification!(version, spec)

    if rubygem.unowned?
      if api_key.user?
        rubygem.create_ownership(owner)
      elsif api_key.trusted_publisher?
        pending_publisher = find_pending_trusted_publisher
        return notify("No pending publisher found", 404) if pending_publisher.blank?

        rubygem.transaction do
          logger.info { "Reifying pending publisher" }
          rubygem.create_ownership(pending_publisher.user)
          owner.rubygem_trusted_publishers.create!(rubygem: rubygem)
        end
      else
        return notify_unauthorized
      end
    end

    true
  rescue ActiveRecord::RecordInvalid, ActiveRecord::Rollback, ActiveRecord::RecordNotUnique => e
    logger.info { { message: "Error updating rubygem", exception: e } }
    false
  end

  def republish_notification(version)
    if version.indexed?
      notify("Repushing of gem versions is not allowed.\n" \
             "Please bump the version number and push a new different release.\n" \
             "See also `gem yank` if you want to unpublish the bad release.", 409)
    elsif version.deletion.nil?
      notify("It appears that #{version.full_name} did not finish pushing.\n" \
             "Please contact support@rubygems.org for assistance if you pushed this gem more than a minute ago.", 409)
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
    RubygemFs.instance.store(gem_path, gem_contents, checksum_sha256: version.sha256,
                             metadata: {
                               "gem" => version.rubygem.name, "version" => version.number, "platform" => version.platform,
                               "surrogate-key" => "gem/#{version.rubygem.name}", "sha256" => version.sha256
                             })
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

  def serialize_spec # rubocop:disable Naming/PredicateMethod
    spec = self.spec.dup
    spec.abbreviate
    spec.sanitize
    @spec_contents = Gem.deflate(Marshal.dump(spec))
    true
  end

  def find_pending_trusted_publisher
    return unless api_key.trusted_publisher?
    owner.pending_trusted_publishers.unexpired.rubygem_name_is(rubygem.name).first
  end

  def sigstore_verifier
    @sigstore_verifier ||= Sigstore::Verifier.production
  end
end
