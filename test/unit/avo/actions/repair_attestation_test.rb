require "test_helper"

class RepairAttestationTest < ActiveSupport::TestCase
  make_my_diffs_pretty!

  setup do
    @view_context = mock
    @avo = mock
    @view_context.stubs(:avo).returns(@avo)
    @avo.stubs(:resources_audit_path).returns("resources_audit_path")
    Avo::Current.stubs(:view_context).returns(@view_context)
    @admin = create(:admin_github_user, :is_admin)
    @version = create(:version)
  end

  test "repairs attestation with missing kindVersion" do
    attestation = Attestation.create!(
      version: @version,
      media_type: "application/vnd.dev.sigstore.bundle.v0.3+json",
      body: {
        "verificationMaterial" => {
          "tlogEntries" => [{ "logIndex" => 123 }],
          "certificate" => { "rawBytes" => Base64.strict_encode64("DER data") }
        }
      }
    )

    assert_predicate attestation, :repairable?

    action = Avo::Actions::RepairAttestation.new
    action.handle(
      fields: { comment: "Repairing invalid attestation" },
      current_user: @admin,
      resource: nil,
      records: [attestation],
      query: nil
    )

    attestation.reload

    refute_predicate attestation, :repairable?
    assert_equal(
      { "kind" => "dsse", "version" => "0.0.1" },
      attestation.body.dig("verificationMaterial", "tlogEntries", 0, "kindVersion")
    )
  end

  test "repairs attestation with double-encoded PEM certificate" do
    key = OpenSSL::PKey::RSA.new(2048)
    cert = OpenSSL::X509::Certificate.new
    cert.version = 2
    cert.serial = 1
    cert.subject = OpenSSL::X509::Name.parse("/CN=Test")
    cert.issuer = cert.subject
    cert.public_key = key.public_key
    cert.not_before = Time.current
    cert.not_after = Time.current + 3600
    cert.sign(key, OpenSSL::Digest.new("SHA256"))

    pem_cert = cert.to_pem
    double_encoded = Base64.strict_encode64(pem_cert)

    attestation = Attestation.create!(
      version: @version,
      media_type: "application/vnd.dev.sigstore.bundle.v0.3+json",
      body: {
        "verificationMaterial" => {
          "tlogEntries" => [{ "kindVersion" => { "kind" => "dsse", "version" => "0.0.1" } }],
          "certificate" => { "rawBytes" => double_encoded }
        }
      }
    )

    assert_predicate attestation, :repairable?

    action = Avo::Actions::RepairAttestation.new
    action.handle(
      fields: { comment: "Repairing invalid attestation" },
      current_user: @admin,
      resource: nil,
      records: [attestation],
      query: nil
    )

    attestation.reload

    refute_predicate attestation, :repairable?

    raw_bytes = attestation.body.dig("verificationMaterial", "certificate", "rawBytes")
    decoded = Base64.strict_decode64(raw_bytes)

    refute decoded.start_with?("-----BEGIN CERTIFICATE-----")
  end

  test "does nothing for attestation without known issues" do
    attestation = Attestation.create!(
      version: @version,
      media_type: "application/vnd.dev.sigstore.bundle.v0.3+json",
      body: {
        "verificationMaterial" => {
          "tlogEntries" => [{ "kindVersion" => { "kind" => "dsse", "version" => "0.0.1" } }],
          "certificate" => { "rawBytes" => Base64.strict_encode64("DER data") }
        }
      }
    )

    refute_predicate attestation, :repairable?
    original_body = attestation.body.deep_dup

    action = Avo::Actions::RepairAttestation.new
    action.handle(
      fields: { comment: "Attempting repair on valid attestation" },
      current_user: @admin,
      resource: nil,
      records: [attestation],
      query: nil
    )

    attestation.reload

    assert_equal original_body, attestation.body
  end

  test "repairs both missing kindVersion and double-encoded certificate simultaneously" do
    key = OpenSSL::PKey::RSA.new(2048)
    cert = OpenSSL::X509::Certificate.new
    cert.version = 2
    cert.serial = 1
    cert.subject = OpenSSL::X509::Name.parse("/CN=Test")
    cert.issuer = cert.subject
    cert.public_key = key.public_key
    cert.not_before = Time.current
    cert.not_after = Time.current + 3600
    cert.sign(key, OpenSSL::Digest.new("SHA256"))

    pem_cert = cert.to_pem
    double_encoded = Base64.strict_encode64(pem_cert)

    attestation = Attestation.create!(
      version: @version,
      media_type: "application/vnd.dev.sigstore.bundle.v0.3+json",
      body: {
        "verificationMaterial" => {
          "tlogEntries" => [{ "logIndex" => 123 }],
          "certificate" => { "rawBytes" => double_encoded }
        }
      }
    )

    assert_predicate attestation, :repairable?

    action = Avo::Actions::RepairAttestation.new
    action.handle(
      fields: { comment: "Repairing attestation with both issues" },
      current_user: @admin,
      resource: nil,
      records: [attestation],
      query: nil
    )

    attestation.reload

    refute_predicate attestation, :repairable?

    # Verify kindVersion was added
    assert_equal(
      { "kind" => "dsse", "version" => "0.0.1" },
      attestation.body.dig("verificationMaterial", "tlogEntries", 0, "kindVersion")
    )

    # Verify certificate was converted to DER
    raw_bytes = attestation.body.dig("verificationMaterial", "certificate", "rawBytes")
    decoded = Base64.strict_decode64(raw_bytes)

    refute decoded.start_with?("-----BEGIN CERTIFICATE-----")
  end
end
