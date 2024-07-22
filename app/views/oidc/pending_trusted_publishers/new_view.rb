# frozen_string_literal: true

class OIDC::PendingTrustedPublishers::NewView < ApplicationView
  include Phlex::Rails::Helpers::LinkTo
  include Phlex::Rails::Helpers::SelectTag
  include Phlex::Rails::Helpers::OptionsForSelect
  include Phlex::Rails::Helpers::FormWith

  extend Dry::Initializer

  option :pending_trusted_publisher

  def view_template
    self.title = t(".title")

    div(class: "t-body") do
      form_with(
        model: pending_trusted_publisher,
        url: profile_oidc_pending_trusted_publishers_path
      ) do |f|
        f.label :rubygem_name, class: "form__label"
        f.text_field :rubygem_name, class: "form__input", autocomplete: :off
        p(class: "form__field__instructions") { t("oidc.trusted_publisher.pending.rubygem_name_help_html") }

        f.label :trusted_publisher_type, class: "form__label"
        f.select :trusted_publisher_type, OIDC::TrustedPublisher.all.map { |type|
                                            [type.publisher_name, type.polymorphic_name]
                                          }, {}, class: "form__input form__select"

        render OIDC::TrustedPublisher::GitHubAction::FormComponent.new(
          github_action_form: f
        )
        f.submit class: "form__submit"
      end
    end
  end
end
