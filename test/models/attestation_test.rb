require "test_helper"

class AttestationTest < ActiveSupport::TestCase
  should belong_to(:version)
  should validate_presence_of(:media_type)
  should validate_presence_of(:body)

  context "#repairable?" do
    setup do
      @version = create(:version)
    end

    should "not be repairable when verificationMaterial is missing" do
      attestation = Attestation.new(
        version: @version,
        media_type: "application/vnd.dev.sigstore.bundle.v0.3+json",
        body: {}
      )

      refute_predicate attestation, :repairable?
    end

    should "be repairable when kindVersion is missing from tlog entry" do
      attestation = Attestation.new(
        version: @version,
        media_type: "application/vnd.dev.sigstore.bundle.v0.3+json",
        body: {
          "verificationMaterial" => {
            "tlogEntries" => ["logIndex" => 123],
            "certificate" => { "rawBytes" => Base64.strict_encode64("DER data") }
          }
        }
      )

      assert_predicate attestation, :repairable?
    end

    should "be repairable when certificate is double-encoded PEM" do
      pem_cert = "-----BEGIN CERTIFICATE-----\nMIIBkTCB+wIJAKHBfpN...\n-----END CERTIFICATE-----\n"
      double_encoded = Base64.strict_encode64(pem_cert)

      attestation = Attestation.new(
        version: @version,
        media_type: "application/vnd.dev.sigstore.bundle.v0.3+json",
        body: {
          "verificationMaterial" => {
            "tlogEntries" => ["kindVersion" => { "kind" => "hashedrekord", "version" => "0.0.1" }],
            "certificate" => { "rawBytes" => double_encoded }
          }
        }
      )

      assert_predicate attestation, :repairable?
    end

    should "not be repairable when bundle has no known issues" do
      attestation = Attestation.new(
        version: @version,
        media_type: "application/vnd.dev.sigstore.bundle.v0.3+json",
        body: {
          "verificationMaterial" => {
            "tlogEntries" => ["kindVersion" => { "kind" => "hashedrekord", "version" => "0.0.1" }],
            "certificate" => { "rawBytes" => Base64.strict_encode64("DER data") }
          }
        }
      )

      refute_predicate attestation, :repairable?
    end
  end

  context "#repair_issues" do
    setup do
      @version = create(:version)
    end

    should "return empty array when no issues" do
      attestation = Attestation.new(
        version: @version,
        media_type: "application/vnd.dev.sigstore.bundle.v0.3+json",
        body: {
          "verificationMaterial" => {
            "tlogEntries" => ["kindVersion" => { "kind" => "hashedrekord", "version" => "0.0.1" }],
            "certificate" => { "rawBytes" => Base64.strict_encode64("DER data") }
          }
        }
      )

      assert_empty attestation.repair_issues
    end

    should "return kindVersion issue when missing" do
      attestation = Attestation.new(
        version: @version,
        media_type: "application/vnd.dev.sigstore.bundle.v0.3+json",
        body: {
          "verificationMaterial" => {
            "tlogEntries" => ["logIndex" => 123],
            "certificate" => { "rawBytes" => Base64.strict_encode64("DER data") }
          }
        }
      )

      issues = attestation.repair_issues

      assert_equal 1, issues.length
      assert_includes issues.first, "kindVersion"
    end

    should "return certificate issue when double-encoded" do
      pem_cert = "-----BEGIN CERTIFICATE-----\nMIIBkTCB+wIJAKHBfpN...\n-----END CERTIFICATE-----\n"
      double_encoded = Base64.strict_encode64(pem_cert)

      attestation = Attestation.new(
        version: @version,
        media_type: "application/vnd.dev.sigstore.bundle.v0.3+json",
        body: {
          "verificationMaterial" => {
            "tlogEntries" => ["kindVersion" => { "kind" => "hashedrekord", "version" => "0.0.1" }],
            "certificate" => { "rawBytes" => double_encoded }
          }
        }
      )

      issues = attestation.repair_issues

      assert_equal 1, issues.length
      assert_includes issues.first, "certificate"
    end

    should "return both issues when both present" do
      pem_cert = "-----BEGIN CERTIFICATE-----\nMIIBkTCB+wIJAKHBfpN...\n-----END CERTIFICATE-----\n"
      double_encoded = Base64.strict_encode64(pem_cert)

      attestation = Attestation.new(
        version: @version,
        media_type: "application/vnd.dev.sigstore.bundle.v0.3+json",
        body: {
          "verificationMaterial" => {
            "tlogEntries" => ["logIndex" => 123],
            "certificate" => { "rawBytes" => double_encoded }
          }
        }
      )

      issues = attestation.repair_issues

      assert_equal 2, issues.length
    end
  end

  context "#valid_bundle?" do
    setup do
      @version = create(:version)
    end

    should "return true for a valid sigstore bundle" do
      attestation = create(:attestation, version: @version)

      assert_predicate attestation, :valid_bundle?
    end

    should "return false with an invalid sigstore bundle" do
      attestation = Attestation.new(
        version: @version,
        media_type: "application/vnd.dev.sigstore.bundle.v0.3+json",
        body: { "invalid" => "bundle" }
      )

      refute_predicate attestation, :valid_bundle?
    end

    should "return false when Sigstore::Error is raised" do
      attestation = create(:attestation, version: @version)
      attestation.stubs(:sigstore_bundle).raises(Sigstore::Error.new("test error"))

      refute_predicate attestation, :valid_bundle?
    end

    should "return false and log warning when StandardError is raised" do
      attestation = create(:attestation, version: @version)
      attestation.stubs(:sigstore_bundle).raises(ArgumentError.new("test error"))

      Rails.logger.expects(:warn).with(regexp_matches(/Failed to validate sigstore bundle/))

      refute_predicate attestation, :valid_bundle?
    end

    should "return false when attestation is repairable" do
      attestation = Attestation.new(
        version: @version,
        media_type: "application/vnd.dev.sigstore.bundle.v0.3+json",
        body: {
          "verificationMaterial" => {
            "tlogEntries" => ["logIndex" => 123],
            "certificate" => { "rawBytes" => Base64.strict_encode64("DER data") }
          }
        }
      )

      assert_predicate attestation, :repairable?
      refute_predicate attestation, :valid_bundle?
    end
  end

  context "#repair!" do
    setup do
      @version = create(:version)
    end

    should "return changes array when kindVersion is repaired" do
      attestation = Attestation.create!(
        version: @version,
        media_type: "application/vnd.dev.sigstore.bundle.v0.3+json",
        body: {
          "verificationMaterial" => {
            "tlogEntries" => ["logIndex" => 123],
            "certificate" => { "rawBytes" => Base64.strict_encode64("DER data") }
          }
        }
      )

      changes = attestation.repair!

      assert_kind_of Array, changes
      assert_includes changes.first, "Added missing kindVersion"
      assert_equal(
        { "kind" => "hashedrekord", "version" => "0.0.1" },
        attestation.body.dig("verificationMaterial", "tlogEntries", 0, "kindVersion")
      )
    end

    should "return false when no repair is needed" do
      attestation = Attestation.create!(
        version: @version,
        media_type: "application/vnd.dev.sigstore.bundle.v0.3+json",
        body: {
          "verificationMaterial" => {
            "tlogEntries" => ["kindVersion" => { "kind" => "hashedrekord", "version" => "0.0.1" }],
            "certificate" => { "rawBytes" => Base64.strict_encode64("DER data") }
          }
        }
      )

      result = attestation.repair!

      refute result
    end

    should "return false when verificationMaterial is missing" do
      attestation = Attestation.create!(
        version: @version,
        media_type: "application/vnd.dev.sigstore.bundle.v0.3+json",
        body: { "mediaType" => "application/vnd.dev.sigstore.bundle.v0.3+json" }
      )

      result = attestation.repair!

      refute result
    end

    should "report failure when certificate repair fails" do
      pem_like_but_invalid = "-----BEGIN CERTIFICATE-----\nINVALID\n-----END CERTIFICATE-----\n"
      double_encoded = Base64.strict_encode64(pem_like_but_invalid)

      attestation = Attestation.create!(
        version: @version,
        media_type: "application/vnd.dev.sigstore.bundle.v0.3+json",
        body: {
          "verificationMaterial" => {
            "tlogEntries" => ["kindVersion" => { "kind" => "hashedrekord", "version" => "0.0.1" }],
            "certificate" => { "rawBytes" => double_encoded }
          }
        }
      )

      changes = attestation.repair!

      assert_kind_of Array, changes
      assert(changes.any? { |c| c.include?("Failed to repair certificate") })
    end
  end
end
