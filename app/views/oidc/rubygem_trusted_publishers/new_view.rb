# frozen_string_literal: true

class OIDC::RubygemTrustedPublishers::NewView < ApplicationView
  include Phlex::Rails::Helpers::ContentFor
  include Phlex::Rails::Helpers::FormWith
  include Phlex::Rails::Helpers::LinkTo
  include Phlex::Rails::Helpers::OptionsForSelect
  include Phlex::Rails::Helpers::SelectTag
  include OIDC::RubygemTrustedPublishers::Concerns::Title

  prop :rubygem_trusted_publisher, reader: :public
  prop :trusted_publisher_types, reader: :private
  prop :selected_trusted_publisher_type, reader: :private

  def view_template
    title_content

    form_with(url: new_rubygem_trusted_publisher_path(rubygem_trusted_publisher.rubygem.slug), method: :get, class: "mb-4") do |f|
      f.label :trusted_publisher_type, "Select CI/CD Provider:", class: "form__label"
      f.select :trusted_publisher_type, trusted_publisher_types.map { |type|
                                          [type.publisher_name, type.url_identifier]
                                        }, { selected: selected_trusted_publisher_type&.url_identifier }, class: "form__input form__select"
      f.submit "Select", class: "form__submit"
    end

    if selected_trusted_publisher_type
      div(class: "t-body") do
        form_with(
          model: rubygem_trusted_publisher,
          url: rubygem_trusted_publishers_path(rubygem_trusted_publisher.rubygem.slug)
        ) do |f|
          f.hidden_field :trusted_publisher_type, value: selected_trusted_publisher_type.polymorphic_name

          case rubygem_trusted_publisher.trusted_publisher
          when OIDC::TrustedPublisher::GitHubAction
            render OIDC::TrustedPublisher::GitHubAction::FormComponent.new(github_action_form: f)
          when OIDC::TrustedPublisher::GitLab
            render OIDC::TrustedPublisher::GitLab::FormComponent.new(gitlab_form: f)
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

  delegate :rubygem, to: :rubygem_trusted_publisher
end
