# frozen_string_literal: true

class Avo::Resources::OIDCProvider < Avo::BaseResource
  self.title = :issuer
  self.includes = []
  self.model_class = ::OIDC::Provider

  def actions
    action Avo::Actions::RefreshOIDCProvider
  end

  def fields
    field :issuer, as: :text, link_to_resource: true
    # The configuration is the issuer's OIDC discovery document, kept up to date
    # by Avo::Actions::RefreshOIDCProvider. Editing it by hand would be undone by
    # the next refresh, and `jwks_uri` is where that refresh fetches the signing
    # keys from, so it is shown but not editable.
    field :configuration, as: :nested, disabled: true do
      visible_on = %i[edit new]
      OIDC::Provider::Configuration.then { it.required_attributes + it.optional_attributes }.each do |k|
        field k, as: (k.to_s.end_with?("s_supported") ? :tags : :text),
            visible: -> { resource && (visible_on.include?(resource.view) || resource.record.configuration&.send(k).present?) }
      end
    end
    field :jwks, as: :array_of, field: :json_viewer, hide_on: :index
    field :api_key_roles, as: :has_many

    field :id, as: :id
  end
end
