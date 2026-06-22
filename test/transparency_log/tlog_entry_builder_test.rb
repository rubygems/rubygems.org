# frozen_string_literal: true

require "test_helper"

class TransparencyLog::TlogEntryBuilderTest < ActiveSupport::TestCase
  setup do
    @private_key = OpenSSL::PKey::EC.generate("prime256v1")
    @json_payload = '{"gem":"rack","version":"3.0.0"}'
  end

  should "build a hashedrekord entry" do
    entry = TransparencyLog::TlogEntryBuilder.new(@private_key).build(@json_payload)

    assert_equal "0.0.2", entry[:apiVersion]
    assert_equal "hashedrekord", entry[:kind]
  end

  should "produce a verifiable signature" do
    entry = TransparencyLog::TlogEntryBuilder.new(@private_key).build(@json_payload)

    signature = Base64.decode64(
      entry.dig(:spec, :hashedRekordV002, :signature, :content)
    )

    assert @private_key.verify(
      OpenSSL::Digest.new("SHA256"),
      signature,
      @json_payload
    )
  end
end
