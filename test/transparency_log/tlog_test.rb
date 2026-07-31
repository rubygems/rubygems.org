# frozen_string_literal: true

require "test_helper"

class TransparencyLog::TlogTest < ActiveSupport::TestCase
  RESPONSE = '{"logIndex": "10", "logId": {"keyId": "2AtEIMfG6Y41yK0tcwRTBS2tjhOrjKGIpDkHFgp65g0="}, "kindVersion": {"kind": "hashedrekord", "version": "0.0.2"}, "integratedTime": "0", "inclusionPromise": "", "inclusionProof": {"logIndex": "10", "rootHash": "VNORC1iO2BcsWjqyVIVD44LY8zp7DAw3ZmvuW5zm2To=", "treeSize": "11", "hashes": ["fAbZjYbu70PoEv8yMBpH29Y7jWx56My3R3aL1zgtuFo=", "j5t5FH1kBaj3snsNcagZ+Jqa0E/me4lcFpsma0eNb1c="], "checkpoint": {"envelope": "rekor-local\n11\nVNORC1iO2BcsWjqyVIVD44LY8zp7DAw3ZmvuW5zm2To=\n\n— rekor-local 2AtEIA8mfiDu3bsom69h3ZLYTo16RWMVK1vdzgSwOgMiEPuWmthg6GCTxnTA5FRsyG3cVCw3gMMoOeGpN/Gm1KdA6AI=\n— rekor-witness-test KI+4DwAAAABqQpR+JVpT8MYMWMvrMNLplduf8ZyaYHC6X5IjxYvix8NEBwZvQc6Tnlqe3ERpXPviwLsIPYMD/DWWUItmKXOlrxWRCA==\n"}}, "canonicalizedBody": "eyJhcGlWZXJzaW9uIjoiMC4wLjIiLCJraW5kIjoiaGFzaGVkcmVrb3JkIiwic3BlYyI6eyJoYXNoZWRSZWtvcmRWMDAyIjp7ImRhdGEiOnsiYWxnb3JpdGhtIjoiU0hBMl8yNTYiLCJkaWdlc3QiOiJxeUtKRElDd09VQU1yNmhzN29RYjhIa2prN3pGSVMwNGlxUFRSOW9sTTJVPSJ9LCJzaWduYXR1cmUiOnsiY29udGVudCI6Ik1FVUNJUUNGbTdrVzdocTZuMTJnVUV5OUxtQVhmaU5lN2VHcVM1YS9iWXRpVHZqYXFRSWdNMm5SaitmRGJrdldaMWl2Y2MrK1hTWEU1SUNrYlQzZWMveXRwYmJQaWNNPSIsInZlcmlmaWVyIjp7ImtleURldGFpbHMiOiJQS0lYX0VDRFNBX1AyNTZfU0hBXzI1NiIsInB1YmxpY0tleSI6eyJyYXdCeXRlcyI6Ik1Ga3dFd1lIS29aSXpqMENBUVlJS29aSXpqMERBUWNEUWdBRThxTzZZOG16aWd6MnpDeE04SndBb29EZGZqSzhiTkJiMEN3R3p2UFVXcFpWblNUaWxBZ1lIUTJZSkNzbDdhMlhRMmxab0wxY0lSRk1BRHJFTlVhZlZnPT0ifX19fX19"}'

  setup do
    @tlog = TransparencyLog::Tlog.new
    @transparency_log_event = create(:transparency_log_event)
  end

  test "creates entry and posts it to transparency log" do
    stub_request(:post, "http://localhost:3004/api/v2/log/entries")
      .to_return(status: 200, body: RESPONSE)

    @tlog.submit_entry(@transparency_log_event)

    assert_requested :post, "http://localhost:3004/api/v2/log/entries", times: 1
  end

  test "logs error and raises FormatError for malformed entry (400)" do
    stub_request(:post, "http://localhost:3004/api/v2/log/entries")
      .to_return(status: 400, body: "Bad Request")

    error = assert_raises TransparencyLog::Tlog::FormatError do
      @tlog.submit_entry(@transparency_log_event)
    end

    assert_equal "Malformed entry (400): Bad Request", error.message
  end

  test "logs error and raises for other client or server errors" do
    stub_request(:post, "http://localhost:3004/api/v2/log/entries")
      .to_return(status: 500, body: "Internal Server Error")

    error = assert_raises TransparencyLog::Tlog::Error do
      @tlog.submit_entry(@transparency_log_event)
    end

    assert_equal "Request failed (500)", error.message
  end

  test "records parsed Rekor response" do
    stub_request(:post, "http://localhost:3004/api/v2/log/entries")
      .to_return(status: 200, body: RESPONSE)

    @tlog.submit_entry(@transparency_log_event)
    @transparency_log_event.reload

    assert_predicate @transparency_log_event, :submitted?
    assert_equal "rekor-local", @transparency_log_event.rekor_log_origin
    assert_equal "hashedrekord", @transparency_log_event.rekor_entry_kind
    assert_equal "0.0.2", @transparency_log_event.rekor_entry_version
    assert_equal 10, @transparency_log_event.rekor_log_index
    assert_equal JSON.parse(RESPONSE).dig("inclusionProof", "checkpoint", "envelope"), @transparency_log_event.rekor_checkpoint
    assert_equal JSON.parse(RESPONSE)["inclusionProof"], @transparency_log_event.rekor_inclusion_proof
  end

  test "persists the complete raw response body" do
    stub_request(:post, "http://localhost:3004/api/v2/log/entries")
      .to_return(status: 200, body: RESPONSE)

    @tlog.submit_entry(@transparency_log_event)
    @transparency_log_event.reload

    assert_equal JSON.parse(RESPONSE), @transparency_log_event.rekor_response_body
  end
end
