# frozen_string_literal: true

class OIDC::ApiKeyRole::TableComponent < ApplicationComponent
  include Phlex::Rails::Helpers::LinkTo

  prop :api_key_roles, reader: :public

  def view_template
    table(class: "w-full text-left border-separate") do
      thead do
        tr do
          header { OIDC::ApiKeyRole.human_attribute_name(:name) }
          header { OIDC::ApiKeyRole.human_attribute_name(:token) }
          header { OIDC::ApiKeyRole.human_attribute_name(:issuer) }
        end
      end

      tbody do
        api_key_roles.each do |api_key_role|
          tr(class: "text-sm") do
            cell(title: "Name") { link_to api_key_role.name, profile_oidc_api_key_role_path(token: api_key_role.token), class: "hover:underline" }
            cell(title: "Role Token") { code { api_key_role.token } }
            cell(title: "Provider") { link_to api_key_role.provider.issuer, api_key_role.provider.issuer, class: LINK_CLASSES }
          end
        end
      end
    end
  end

  private

  LINK_CLASSES = "text-orange-500 hover:underline dark:text-orange-400"

  def header(&)
    th(&)
  end

  def cell(title:, &)
    td(data: { title: }, &)
  end
end
