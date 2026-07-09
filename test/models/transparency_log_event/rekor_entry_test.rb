# frozen_string_literal: true

require "test_helper"

# Exercises the normalized Rekor evidence value object.
class TransparencyLogEvent::RekorEntryTest < ActiveSupport::TestCase
  should "map normalized evidence to transparency log event attributes" do
    inclusion_proof = { "treeSize" => 2, "hashes" => ["abc"] }
    rekor_entry = TransparencyLogEvent::RekorEntry.new(
      response_body: { "uuid" => "rekor-entry-uuid" },
      origin: "rekor.sigstore.dev",
      kind: "hashedrekord",
      version: "0.0.1",
      index: 123,
      checkpoint: "checkpoint",
      inclusion_proof:
    )

    assert_equal(
      {
        rekor_log_origin: "rekor.sigstore.dev",
        rekor_entry_kind: "hashedrekord",
        rekor_entry_version: "0.0.1",
        rekor_log_index: 123,
        rekor_checkpoint: "checkpoint",
        rekor_inclusion_proof: inclusion_proof
      },
      rekor_entry.event_attributes
    )
  end
end
