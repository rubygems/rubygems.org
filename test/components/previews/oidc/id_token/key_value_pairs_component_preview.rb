class OIDC::IdToken::KeyValuePairsComponentPreview < Lookbook::Preview
  # @param key text
  # @param value text
  def default(key: "key", value: "value")
    pairs = {
      "sub" => "1234567890",
      "name" => "John Doe",
      "given_name" => "John",
      "family_name" => "Doe",
      "preferred_username" => "johndoe",
      key => value
    }
    render OIDC::IdToken::KeyValuePairsComponent.new(pairs:)
  end

  def empty
    render OIDC::IdToken::KeyValuePairsComponent.new(pairs: {})
  end
end
