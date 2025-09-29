# frozen_string_literal: true

class OIDC::PendingTrustedPublishers::NewView < ApplicationView
  include Phlex::Rails::Helpers::LinkTo
  include Phlex::Rails::Helpers::SelectTag
  include Phlex::Rails::Helpers::OptionsForSelect
  include Phlex::Rails::Helpers::FormWith

  prop :pending_trusted_publisher, reader: :public
  prop :trusted_publisher_types, reader: :private
  prop :selected_trusted_publisher_type, reader: :private

  def view_template
    self.title = t(".title")

    # Form for selecting trusted publisher type
    form_with(url: new_profile_oidc_pending_trusted_publisher_path, method: :get, class: "mb-4") do |f|
      f.label :trusted_publisher_type, "Select CI/CD Provider:", class: "form__label"
      f.select :trusted_publisher_type, trusted_publisher_types.map { |type|
                                          [type.publisher_name, type.polymorphic_name]
                                        }, { selected: selected_trusted_publisher_type&.polymorphic_name }, class: "form__input form__select"
      f.submit "Select", class: "form__submit"
    end

    if selected_trusted_publisher_type
      div(class: "t-body") do
        form_with(
          model: pending_trusted_publisher,
          url: profile_oidc_pending_trusted_publishers_path
        ) do |f|
          f.label :rubygem_name, class: "form__label"
          f.text_field :rubygem_name, class: "form__input", autocomplete: :off
          p(class: "form__field__instructions") { t("oidc.trusted_publisher.pending.rubygem_name_help_html") }

          f.hidden_field :trusted_publisher_type, value: selected_trusted_publisher_type.polymorphic_name

          case pending_trusted_publisher.trusted_publisher
          when OIDC::TrustedPublisher::GitHubAction
            render OIDC::TrustedPublisher::GitHubAction::FormComponent.new(
              github_action_form: f
            )
          when OIDC::TrustedPublisher::GitLab
            render OIDC::TrustedPublisher::GitLab::FormComponent.new(
              gitlab_form: f
            )
          end
          f.submit class: "form__submit"
        end
      end
    else
      div(class: "t-body") do
        # p "Please select a CI/CD provider to create a pending trusted publisher."
      end
    end
  end
end
