# frozen_string_literal: true

require "test_helper"

class TransparencyLogEvent::RekorResponseTest < ActiveSupport::TestCase
  setup do
    @checkpoint = "rekor-local\n11\nroot-hash\n\n— rekor-local signature\n"
    @inclusion_proof = {
      "logIndex" => "10",
      "rootHash" => "root-hash",
      "treeSize" => "11",
      "hashes" => ["hash-one", "hash-two"],
      "checkpoint" => { "envelope" => @checkpoint }
    }
    @response_body = {
      "logIndex" => "10",
      "logId" => { "keyId" => "key-id" },
      "kindVersion" => { "kind" => "hashedrekord", "version" => "0.0.2" },
      "inclusionProof" => @inclusion_proof
    }
  end

  test "parses Rekor response" do
    response = TransparencyLogEvent::RekorResponse.from_json(@response_body)

    assert_equal @response_body, response.response_body
    assert_equal "rekor-local", response.origin
    assert_equal "hashedrekord", response.kind
    assert_equal "0.0.2", response.version
    assert_equal "10", response.index
    assert_equal @checkpoint, response.checkpoint
    assert_equal @inclusion_proof, response.inclusion_proof
  end

  test "maps response to transparency log event attributes" do
    response = TransparencyLogEvent::RekorResponse.from_json(@response_body)

    assert_equal(
      {
        rekor_log_origin: "rekor-local",
        rekor_entry_kind: "hashedrekord",
        rekor_entry_version: "0.0.2",
        rekor_log_index: "10",
        rekor_checkpoint: @checkpoint,
        rekor_inclusion_proof: @inclusion_proof
      },
      response.event_attributes
    )
  end
end