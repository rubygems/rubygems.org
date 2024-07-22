class OIDC::IdToken::TableComponentPreview < Lookbook::Preview
  def default(id_tokens: OIDC::IdToken.limit(3))
    render OIDC::IdToken::TableComponent.new(
      id_tokens:
    )
  end
end
