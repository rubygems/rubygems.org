class OIDC::ApiKeyRole::TableComponentPreview < Lookbook::Preview
  def default(api_key_roles: OIDC::ApiKeyRole.limit(3))
    render OIDC::ApiKeyRole::TableComponent.new(
      api_key_roles:
    )
  end
end
