# frozen_string_literal: true

class OIDC::IdToken::TableComponent < ApplicationComponent
  prop :id_tokens, reader: :public

  include Phlex::Rails::Helpers::TimeTag
  include Phlex::Rails::Helpers::LinkToUnlessCurrent

  def view_template
    table(class: "w-full text-left border-separate") do
      thead do
        tr do
          th { OIDC::IdToken.human_attribute_name(:created_at) }
          th { OIDC::IdToken.human_attribute_name(:expires_at) }
          th { OIDC::IdToken.human_attribute_name(:api_key_role) }
          th { OIDC::IdToken.human_attribute_name(:jti) }
        end
      end

      tbody do
        id_tokens.each do |token|
          row(token)
        end
      end
    end
  end

  private

  LINK_CLASSES = "text-orange-500 hover:underline dark:text-orange-400"

  def row(token)
    row_classes = ["text-sm"]
    row_classes << "text-neutral-500 dark:text-neutral-500" if token.api_key.expired?
    tr(class: row_classes.join(" ")) do
      td { time_tag token.created_at }
      td { time_tag token.api_key.expires_at }
      td { link_to_unless_current token.api_key_role.name, profile_oidc_api_key_role_path(token.api_key_role.token), class: LINK_CLASSES }
      td { link_to_unless_current token.jti, profile_oidc_id_token_path(token), class: LINK_CLASSES }
    end
  end
end
