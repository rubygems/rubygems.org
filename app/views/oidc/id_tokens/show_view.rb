# frozen_string_literal: true

class OIDC::IdTokens::ShowView < ApplicationView
  extend Dry::Initializer
  include Phlex::Rails::Helpers::TimeTag
  include Phlex::Rails::Helpers::LinkTo

  option :id_token

  def template # rubocop:disable Metrics/AbcSize
    self.title = t(".title")

    div(class: "t-body") do
      section(:created_at) { time_tag id_token.created_at }
      section(:expires_at) { time_tag id_token.api_key.expires_at }
      section(:jti) { code { id_token.jti } }
      section(:api_key_role) { link_to id_token.api_key_role.name, profile_oidc_api_key_role_path(id_token.api_key_role.token) }
      section(:provider) { link_to id_token.provider.issuer, profile_oidc_provider_path(id_token.provider) }
      section(:claims) { render OIDC::IdToken::KeyValuePairsComponent.new(pairs: id_token.claims) }
      section(:header) { render OIDC::IdToken::KeyValuePairsComponent.new(pairs: id_token.header) }
    end
  end

  private

  def section(header, &)
    h3(class: "t-list__heading") { id_token.class.human_attribute_name(header) }
    div(class: "push--s", &)
  end
end
