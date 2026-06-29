# frozen_string_literal: true

class OIDC::IdTokens::ShowView < ApplicationView
  include Phlex::Rails::Helpers::TimeTag
  include Phlex::Rails::Helpers::LinkTo
  include Phlex::Rails::Helpers::ContentFor

  prop :id_token, reader: :public

  def view_template # rubocop:disable Metrics/AbcSize
    self.title = t(".title")

    subject_sidebar

    render CardComponent.new do |c|
      c.head { c.title(t(".title"), icon: "settings") }

      section(:created_at) { time_tag id_token.created_at }
      section(:expires_at) { time_tag id_token.api_key.expires_at }
      section(:jti) { code { id_token.jti } }
      section(:api_key_role) { link_to id_token.api_key_role.name, profile_oidc_api_key_role_path(id_token.api_key_role.token), class: LINK_CLASSES }
      section(:provider) { link_to id_token.provider.issuer, profile_oidc_provider_path(id_token.provider), class: LINK_CLASSES }
      section(:claims) { render OIDC::IdToken::KeyValuePairsComponent.new(pairs: id_token.claims) }
      section(:header) { render OIDC::IdToken::KeyValuePairsComponent.new(pairs: id_token.header) }
    end
  end

  private

  HEADING = "text-sm text-neutral-600 dark:text-neutral-400 uppercase tracking-wide"
  LINK_CLASSES = "text-orange-500 hover:underline dark:text-orange-400"

  def subject_sidebar
    content_for :subject do
      view_context.render(partial: "dashboards/subject", locals: { user: current_user, current: :profile })
    end
  end

  def section(header, &)
    h3(class: HEADING) { id_token.class.human_attribute_name(header) }
    div(class: "mt-1 mb-6", &)
  end
end
