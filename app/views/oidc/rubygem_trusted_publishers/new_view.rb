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

    div(class: "t-body") do
      form_with(
        model: rubygem_trusted_publisher,
        url: rubygem_trusted_publishers_path(rubygem_trusted_publisher.rubygem.slug),
        data: { controller: "form-submit" }
      ) do |f|
        f.label :trusted_publisher_type, class: "form__label"
        if selected_trusted_publisher_type
          p { selected_trusted_publisher_type.publisher_name }
          f.hidden_field :trusted_publisher_type, value: selected_trusted_publisher_type.polymorphic_name
        else
          f.select :trusted_publisher_type, trusted_publisher_types.map { |type|
            [type.publisher_name, type.polymorphic_name]
          }, { include_blank: "Select a trusted publisher type", selected: selected_trusted_publisher_type&.polymorphic_name }, class: "form__input form__select", data: { action: "change->form-submit#submitForm" }
        end

        if selected_trusted_publisher_type
          if selected_trusted_publisher_type == OIDC::TrustedPublisher::GitHubAction
            render selected_trusted_publisher_type.form_component.new(github_action_form: f)
          elsif selected_trusted_publisher_type == OIDC::TrustedPublisher::GitLab
            render selected_trusted_publisher_type.form_component.new(form: f)
          end
        end
        f.submit class: "form__submit"
      end
    end
  end

  delegate :rubygem, to: :rubygem_trusted_publisher
end
