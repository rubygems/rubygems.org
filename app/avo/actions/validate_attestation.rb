class Avo::Actions::ValidateAttestation < Avo::Actions::ApplicationAction
  self.name = "Validate attestation"
  self.visible = lambda {
    current_user.team_member?("rubygems-org") && view == :show
  }
  self.message = "This will perform a full end-to-end validation of the attestation against the gem file. Proceed?"
  self.confirm_button_label = "Validate attestation"

  class ActionHandler < Avo::Actions::ActionHandler
    # Timeout for external Sigstore verification calls (in seconds)
    VERIFICATION_TIMEOUT = 30

    # Skip comment validation and provide default comment for audit
    reset_callbacks :handle

    def fields
      @fields.reverse_merge(comment: "Attestation validation check")
    end

    def handle_record(attestation)
      result = validate_attestation(attestation)

      if result[:success]
        succeed result[:message]
      else
        error result[:message]
      end
    end

    private

    def validate_attestation(attestation)
      version = attestation.version

      # Fetch the gem file
      gem_contents = RubygemFs.instance.get("gems/#{version.gem_file_name}")
      return { success: false, message: "Gem file not found in storage" } unless gem_contents

      # Parse the sigstore bundle
      bundle = attestation.sigstore_bundle
      return { success: false, message: "Failed to parse sigstore bundle" } unless bundle

      # Extract identity from the certificate for policy verification
      policy = extract_policy_from_certificate(bundle.leaf_certificate)
      return { success: false, message: "Failed to extract identity from certificate" } unless policy

      # Build verification input
      artifact = Sigstore::Verification::V1::Artifact.new
      artifact.artifact = gem_contents

      verification_input = Sigstore::Verification::V1::Input.new
      verification_input.artifact = artifact
      verification_input.bundle = bundle.inner
      input = Sigstore::VerificationInput.new(verification_input)

      # Verify the attestation against Sigstore's Rekor transparency log.
      # Note: This makes external network calls to Sigstore services.
      verifier = Sigstore::Verifier.production
      result = Timeout.timeout(VERIFICATION_TIMEOUT) do
        verifier.verify(input:, policy:, offline: false)
      end

      if result.verified?
        { success: true, message: "Attestation verified successfully against gem file" }
      else
        { success: false, message: "Verification failed: #{result.reason}" }
      end
    rescue Timeout::Error
      { success: false, message: "Verification timed out after #{VERIFICATION_TIMEOUT} seconds" }
    rescue Sigstore::Error => e
      { success: false, message: "Sigstore error: #{e.message}" }
    rescue StandardError => e
      Rails.logger.error("Attestation validation error: #{e.class}: #{e.message}\n#{e.backtrace&.first(5)&.join("\n")}")
      { success: false, message: "Validation error: #{e.class}: #{e.message}" }
    end

    def extract_policy_from_certificate(leaf_certificate)
      # Extract issuer from Fulcio extension
      issuer = leaf_certificate.extension(Sigstore::Internal::X509::Extension::FulcioIssuer).issuer

      # Extract identity from Subject Alternative Name
      san_extension = leaf_certificate.openssl.extensions.find { |ext| ext.oid == "subjectAltName" }
      return nil unless san_extension

      # SAN format is "URI:https://github.com/owner/repo/.github/workflows/workflow.yml@refs/..."
      san_value = san_extension.value
      identity = san_value.delete_prefix("URI:")

      Sigstore::Policy::Identity.new(identity:, issuer:)
    rescue StandardError
      nil
    end
  end
end
