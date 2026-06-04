# frozen_string_literal: true

class OIDC::RubygemTrustedPublishers::NewView < ApplicationView
  include Phlex::Rails::Helpers::FormWith
  include Phlex::Rails::Helpers::LinkTo
  include Phlex::Rails::Helpers::OptionsForSelect
  include Phlex::Rails::Helpers::SelectTag
  include OIDC::RubygemTrustedPublishers::Concerns::Title

  prop :rubygem_trusted_publisher, reader: :public
  prop :trusted_publisher_types, reader: :private
  prop :selected_trusted_publisher_type, reader: :private

  delegate :rubygem, to: :rubygem_trusted_publisher

  def view_template
    gem_subject_page do
      form_with(url: new_rubygem_trusted_publisher_path(rubygem_trusted_publisher.rubygem.slug), method: :get, class: "mb-4") do |f|
        f.label :trusted_publisher_type, "Select CI/CD Provider:", class: label_class
        f.select :trusted_publisher_type, trusted_publisher_types.map { |type|
                                            [type.publisher_name, type.url_identifier]
                                          }, { selected: selected_trusted_publisher_type&.url_identifier }, class: field_class
        f.submit "Select", class: "inline-flex items-center justify-center rounded border-2 border-orange-600 " \
                                  "text-orange-600 px-4 h-9 min-h-9 text-b3 hover:bg-orange-600/5 " \
                                  "active:bg-orange-600/10 transition focus:outline-none mt-2"
      end

      if selected_trusted_publisher_type
        render CardComponent.new do
          form_with(
            model: rubygem_trusted_publisher,
            url: rubygem_trusted_publishers_path(rubygem.slug)
          ) do |f|
            f.hidden_field :trusted_publisher_type, value: selected_trusted_publisher_type.polymorphic_name

            case rubygem_trusted_publisher.trusted_publisher
            when OIDC::TrustedPublisher::GitHubAction
              render OIDC::TrustedPublisher::GitHubAction::FormComponent.new(github_action_form: f)
            when OIDC::TrustedPublisher::GitLab
              render OIDC::TrustedPublisher::GitLab::FormComponent.new(gitlab_form: f)
            end

            render ButtonComponent.new do
              f.submit
            end
          end
        end
      end
    end
  end

  private

  def label_class
    "block text-b4 font-semibold text-neutral-800 dark:text-neutral-200 mb-2"
  end

  def field_class
    "block w-full rounded border border-neutral-300 dark:border-neutral-700 " \
      "bg-white dark:bg-neutral-900 text-neutral-900 dark:text-white px-3 h-12 " \
      "outline-none focus:border-neutral-500 focus:ring-0"
  end
end
