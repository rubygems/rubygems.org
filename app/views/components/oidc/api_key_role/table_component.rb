# frozen_string_literal: true

class OIDC::ApiKeyRole::TableComponent < ApplicationComponent
  include Phlex::Rails::Helpers::LinkTo
  extend Dry::Initializer

  option :api_key_roles

  def template
    table(class: "t-body") do
      thead do
        tr(class: "owners__row owners__header") do
          header { OIDC::ApiKeyRole.human_attribute_name(:name) }
          header { OIDC::ApiKeyRole.human_attribute_name(:token) }
          header { OIDC::ApiKeyRole.human_attribute_name(:issuer) }
        end
      end

      tbody(class: "t-body") do
        api_key_roles.each do |api_key_role|
          tr(class: "owners__row") do
            cell(title: "Name") { link_to api_key_role.name, profile_oidc_api_key_role_path(api_key_role.token) }
            cell(title: "Role Token") { code { api_key_role.token } }
            cell(title: "Provider") { link_to api_key_role.provider.issuer, api_key_role.provider.issuer }
          end
        end
      end
    end
  end

  private

  def header(&)
    th(class: "owners_cell", &)
  end

  def cell(title:, &)
    td(class: "owners__cell", data: { title: }, &)
  end
end
