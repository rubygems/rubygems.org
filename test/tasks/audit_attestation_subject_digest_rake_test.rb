# frozen_string_literal: true

require "test_helper"
require "helpers/rake_task_helper"

class AuditAttestationSubjectDigestRakeTest < ActiveSupport::TestCase
  include RakeTaskHelper

  setup do
    setup_rake_tasks("audit_attestation_subject_digest.rake")
  end

  def build_dsse_bundle(subject_sha256:)
    in_toto_statement = {
      "_type" => "https://in-toto.io/Statement/v1",
      "subject" => [
        {
          "name" => "test-gem-1.0.0.gem",
          "digest" => { "sha256" => subject_sha256 }
        }
      ]
    }

    payload = JSON.dump(in_toto_statement)

    envelope = stub(
      payloadType: "application/vnd.in-toto+json",
      payload: payload
    )

    stub(
      dsse_envelope?: true,
      dsse_envelope: envelope
    )
  end

  def build_message_signature_bundle
    stub(dsse_envelope?: false)
  end

  context "audit_attestation" do
    should "return match when subject digest matches version SHA256" do
      sha256 = Digest::SHA256.base64digest("gem contents")
      expected_hex = Digest::SHA256.hexdigest("gem contents")

      attestation = create(:attestation, version: create(:version, sha256: sha256))
      attestation.stubs(:sigstore_bundle).returns(build_dsse_bundle(subject_sha256: expected_hex))

      result = audit_attestation(attestation)

      assert_equal :match, result.status
      assert_nil result.detail
    end

    should "return mismatch when subject digest does not match" do
      sha256 = Digest::SHA256.base64digest("gem contents")

      attestation = create(:attestation, version: create(:version, sha256: sha256))
      attestation.stubs(:sigstore_bundle).returns(build_dsse_bundle(subject_sha256: "deadbeef" * 8))

      result = audit_attestation(attestation)

      assert_equal :mismatch, result.status
      assert_match(/subject=/, result.detail)
      assert_match(/version=/, result.detail)
    end

    should "return skipped for non-DSSE bundles" do
      attestation = create(:attestation)
      attestation.stubs(:sigstore_bundle).returns(build_message_signature_bundle)

      result = audit_attestation(attestation)

      assert_equal :skipped, result.status
    end

    should "return skipped when version is missing sha256" do
      version = create(:version)
      version.update_column(:sha256, nil)
      attestation = create(:attestation, version: version)
      hex = Digest::SHA256.hexdigest("anything")
      attestation.stubs(:sigstore_bundle).returns(build_dsse_bundle(subject_sha256: hex))

      result = audit_attestation(attestation)

      assert_equal :skipped, result.status
      assert_match(/missing sha256/, result.detail)
    end

    should "return error on Sigstore::Error" do
      attestation = create(:attestation)
      attestation.stubs(:sigstore_bundle).raises(Sigstore::Error.new("bundle error"))

      result = audit_attestation(attestation)

      assert_equal :error, result.status
      assert_match(/Sigstore::Error/, result.detail)
    end

    should "return skipped for unexpected payload type" do
      envelope = stub(
        payloadType: "application/octet-stream",
        payload: ""
      )
      bundle = stub(dsse_envelope?: true, dsse_envelope: envelope)

      attestation = create(:attestation)
      attestation.stubs(:sigstore_bundle).returns(bundle)

      result = audit_attestation(attestation)

      assert_equal :skipped, result.status
      assert_match(/unexpected payload type/, result.detail)
    end

    should "return error on StandardError" do
      attestation = create(:attestation)
      attestation.stubs(:sigstore_bundle).raises(ArgumentError.new("invalid data"))

      result = audit_attestation(attestation)

      assert_equal :error, result.status
      assert_match(/ArgumentError/, result.detail)
    end

    should "return error on JSON::ParserError" do
      envelope = stub(
        payloadType: "application/vnd.in-toto+json",
        payload: "not json{"
      )
      bundle = stub(dsse_envelope?: true, dsse_envelope: envelope)

      attestation = create(:attestation)
      attestation.stubs(:sigstore_bundle).returns(bundle)

      result = audit_attestation(attestation)

      assert_equal :error, result.status
      assert_match(/JSON::ParserError/, result.detail)
    end
  end

  context "rake task" do
    should "print summary report" do
      sha256 = Digest::SHA256.base64digest("gem contents")
      expected_hex = Digest::SHA256.hexdigest("gem contents")

      create(:attestation, version: create(:version, sha256: sha256))
      Attestation.any_instance.stubs(:sigstore_bundle).returns(build_dsse_bundle(subject_sha256: expected_hex))

      stdout, = capture_io { Rake::Task["audit_attestation_subject_digest"].invoke }

      assert_match(/Audit Summary/, stdout)
      assert_match(/Match:\s+1/, stdout)
      assert_match(/Mismatch:\s+0/, stdout)
    end

    should "respect MAX_ATTESTATION_ID filter" do
      sha256 = Digest::SHA256.base64digest("gem contents")
      expected_hex = Digest::SHA256.hexdigest("gem contents")

      a1 = create(:attestation, version: create(:version, sha256: sha256))
      a2 = create(:attestation, version: create(:version, sha256: sha256))
      Attestation.any_instance.stubs(:sigstore_bundle).returns(build_dsse_bundle(subject_sha256: expected_hex))

      ENV["MAX_ATTESTATION_ID"] = a1.id.to_s
      stdout, = capture_io { Rake::Task["audit_attestation_subject_digest"].invoke }
      ENV.delete("MAX_ATTESTATION_ID")

      assert_match(/Auditing 1 attestations/, stdout)
      assert_match(/Match:\s+1/, stdout)
    end
  end
end
