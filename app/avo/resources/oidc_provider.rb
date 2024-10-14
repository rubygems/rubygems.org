class Avo::Resources::OIDCProvider < Avo::BaseResource
  self.title = :issuer
  self.includes = []
  self.model_class = ::OIDC::Provider

  def actions
    action Avo::Actions::RefreshOIDCProvider
  end

  def fields
    field :issuer, as: :text, link_to_resource: true
    field :configuration, as: :nested do
      visible_on = %i[edit new]
      OIDC::Provider::Configuration.then { _1.required_attributes + _1.optional_attributes }.each do |k|
        field k, as: (k.to_s.end_with?("s_supported") ? :tags : :text),
            visible: -> { resource && (visible_on.include?(resource.view) || resource.record.configuration&.send(k).present?) }
      end
    end
    field :jwks, as: :array_of, field: :json_viewer, hide_on: :index
    field :api_key_roles, as: :has_many

    field :id, as: :id
  end
end
