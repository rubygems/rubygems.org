# frozen_string_literal: true

class OIDC::IdToken::TableComponent < ApplicationComponent
  extend Dry::Initializer
  option :id_tokens

  include Phlex::Rails::Helpers::TimeTag
  include Phlex::Rails::Helpers::LinkToUnlessCurrent

  def view_template
    table(class: "owners__table") do
      thead do
        tr(class: "owners__row owners__header") do
          th(class: "owners__cell") { OIDC::IdToken.human_attribute_name(:created_at) }
          th(class: "owners__cell") { OIDC::IdToken.human_attribute_name(:expires_at) }
          th(class: "owners__cell") { OIDC::IdToken.human_attribute_name(:api_key_role) }
          th(class: "owners__cell") { OIDC::IdToken.human_attribute_name(:jti) }
        end
      end

      tbody(class: "t-body") do
        id_tokens.each do |token|
          row(token)
        end
      end
    end
  end

  private

  def row(token)
    tr(**classes("owners__row", -> { token.api_key.expired? } => "owners__row__invalid")) do
      td(class: "owners__cell") { time_tag token.created_at }
      td(class: "owners__cell") { time_tag token.api_key.expires_at }
      td(class: "owners__cell") { link_to_unless_current token.api_key_role.name, profile_oidc_api_key_role_path(token.api_key_role.token) }
      td(class: "owners__cell") { link_to_unless_current token.jti, profile_oidc_id_token_path(token), class: "recovery-code-list__item" }
    end
  end
end
