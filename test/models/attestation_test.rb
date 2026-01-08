require "test_helper"

class AttestationTest < ActiveSupport::TestCase
  should belong_to(:version)
  should validate_presence_of(:media_type)
  should validate_presence_of(:body)

  context "#repairable?" do
    setup do
      @version = create(:version)
    end

    should "be repairable when verificationMaterial is missing" do
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
            "tlogEntries" => [{ "logIndex" => 123 }],
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
            "tlogEntries" => [{ "kindVersion" => { "kind" => "dsse", "version" => "0.0.1" } }],
            "certificate" => { "rawBytes" => double_encoded }
          }
        }
      )

      assert_predicate attestation, :repairable?
    end

    should "be not repairable when bundle has no known issues" do
      attestation = Attestation.new(
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
    end
  end
end
