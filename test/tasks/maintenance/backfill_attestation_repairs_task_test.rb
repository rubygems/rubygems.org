# frozen_string_literal: true

require "test_helper"

class Maintenance::BackfillAttestationRepairsTaskTest < ActiveSupport::TestCase
  setup do
    @repairable_body = {
      "verificationMaterial" => {
        "tlogEntries" => ["logIndex" => 123],
        "certificate" => { "rawBytes" => Base64.strict_encode64("DER data") }
      }
    }

    @valid_body = {
      "verificationMaterial" => {
        "tlogEntries" => ["kindVersion" => { "kind" => "hashedrekord", "version" => "0.0.1" }],
        "certificate" => { "rawBytes" => Base64.strict_encode64("DER data") }
      }
    }
  end

  context "#collection" do
    should "return attestations with id <= max_attestation_id" do
      included_attestation = create(:attestation, id: 100)
      excluded_attestation = create(:attestation, id: 101)

      task = Maintenance::BackfillAttestationRepairsTask.new
      task.max_attestation_id = 100

      collection = task.collection

      assert_includes collection, included_attestation
      refute_includes collection, excluded_attestation
    end
  end

  context "#process" do
    should "repair a repairable attestation" do
      repairable_attestation = Attestation.create!(
        version: create(:version),
        media_type: "application/vnd.dev.sigstore.bundle.v0.3+json",
        body: @repairable_body
      )

      task = Maintenance::BackfillAttestationRepairsTask.new
      task.process(repairable_attestation)

      repairable_attestation.reload

      assert_equal(
        { "kind" => "hashedrekord", "version" => "0.0.1" },
        repairable_attestation.body.dig("verificationMaterial", "tlogEntries", 0, "kindVersion")
      )
    end

    should "skip attestations that are not repairable" do
      valid_attestation = Attestation.create!(
        version: create(:version),
        media_type: "application/vnd.dev.sigstore.bundle.v0.3+json",
        body: @valid_body
      )

      task = Maintenance::BackfillAttestationRepairsTask.new
      assert_no_changes -> { valid_attestation.reload.body } do
        task.process(valid_attestation)
      end
    end
  end
end
